//
//  ObserverScene.swift
//  Graviton
//
//  Created by Ben Lu on 2/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import StarryNight
import SpaceTime
import MathUtil
import CoreLocation

fileprivate let milkywayLayerRadius: Double = 50
fileprivate let auxillaryLineLayerRadius: Double = 25
let auxillaryConstellationLabelLayerRadius: Double = 24
fileprivate let starLayerRadius: Double = 20
fileprivate let planetLayerRadius: Double = 5
fileprivate let largeBodyScene = SCNScene(named: "art.scnassets/large_bodies.scn")!

class ObserverScene: SCNScene, CameraControlling, FocusingSupport, EphemerisUpdateDelegate {
    
    private struct Category: OptionSet {
        let rawValue: Int
        
        static let `default` = Category(rawValue: 1)
        static let sunlight = Category(rawValue: 2)
        static let moon: Category = [.default, .sunlight]
        static let all: Category = Category(rawValue: ~0)
    }
    
    static let defaultFov: Double = 45
    /// Determines how fast zooming changes fov; the greater this number, the faster
    private static let fovExpBase: Double = 1.25
    private static let maxFov: Double = 120
    private static let minFov: Double = 8
    // scale is inverse proportional to fov
    private static let maxScale: Double = exp2(log(defaultFov / minFov) / log(fovExpBase))
    private static var minScale: Double = exp2(log(defaultFov / maxFov) / log(fovExpBase))
    
    lazy var stars = Star.magitudeLessThan(5.3)
    
    private lazy var camera: SCNCamera = {
        let c = SCNCamera()
        c.automaticallyAdjustsZRange = true
        c.xFov = defaultFov
        c.yFov = defaultFov
        c.categoryBitMask = Category.all.rawValue
        return c
    }()
    
    lazy var cameraNode: SCNNode = {
        let cn = SCNNode()
        cn.camera = self.camera
        return cn
    }()
    
    var focusedNode: SCNNode?

    var scale: Double = 1 {
        didSet {
            let cappedScale = min(max(scale, ObserverScene.minScale), ObserverScene.maxScale)
            self.scale = cappedScale
            self.camera.xFov = self.fov
            self.camera.yFov = self.fov
        }
    }
    
    var fov: Double {
        get {
            return ObserverScene.defaultFov / pow(ObserverScene.fovExpBase, log2(scale))
        }
        set {
            guard fov > 0 else {
                fatalError("fov must be greater than 0")
            }
            let cappedFov = min(max(newValue, ObserverScene.minFov), ObserverScene.maxFov)
            self.scale = exp2(log(ObserverScene.defaultFov / cappedFov) / log(ObserverScene.fovExpBase))
        }
    }
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000
        manager.pausesLocationUpdatesAutomatically = true
        return manager
    }()
    
    var observerInfo: ObserverInfo?
    
    // MARK: - Property - Visual Nodes

    private var celesitalEquatorNode: CelestialEquatorLineNode?
    private var eclipticNode: EclipticLineNode?

    private lazy var milkyWayNode: SCNNode = {
        let node = SphereInteriorNode.init(radius: milkywayLayerRadius, textureLongitudeOffset: -Double.pi / 2)
        node.sphere.firstMaterial!.diffuse.contents = #imageLiteral(resourceName: "milkyway.png")
        node.opacity = 0.3
        return node
    }()
    
    lazy var debugNode: SCNNode = {
        let node = SphereInteriorNode(radius: milkywayLayerRadius - 1)
        node.sphere.firstMaterial!.diffuse.contents = UIColor.white
        node.sphere.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "debug_sphere_directions_transparency")
        // since the coordinate is NED, we rotate around center by 180 degrees to make it upside down
        var mtx = SCNMatrix4MakeTranslation(-0.5, -0.5, 0)
        mtx = SCNMatrix4Rotate(mtx, Float(Double.pi), 0, 0, 1)
        mtx = SCNMatrix4Translate(mtx, 0.5, 0.5, 0)
        node.sphere.firstMaterial!.transparent.contentsTransform = mtx
        node.sphere.firstMaterial!.isDoubleSided = true
        return node
    }()
    
    lazy var sunNode: SCNNode = {
        let sunMat = SCNMaterial()
        sunMat.diffuse.contents = #imageLiteral(resourceName: "sun")
        let sphere = SCNSphere(radius: 0.1)
        sphere.firstMaterial = sunMat
        let node = SCNNode(geometry: sphere)
        node.name = String(Sun.sol.naifId)
        return node
    }()
    
    // MARK: - Functions
    
    override init() {
        super.init()
        resetCamera()
        rootNode.addChildNode(milkyWayNode)
        rootNode.addChildNode(debugNode)
        rootNode.addChildNode(sunNode)
        rootNode.addChildNode(cameraNode)
        drawStars()
        drawConstellationLines()
        drawConstellationLabels()
        
        let southNode = IndicatorNode(setting: .showSouthPoleIndicator, position: SCNVector3(0, 0, -10), color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1))
        southNode.name = "south pole indicator"
        rootNode.addChildNode(southNode)
        let northNode = IndicatorNode(setting: .showNorthPoleIndicator, position: SCNVector3(0, 0, 10), color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1))
        northNode.name = "north pole indicator"
        rootNode.addChildNode(northNode)

        let focuser = FocusIndicatorNode(radius: 0.5)
        focuser.position = SCNVector3(0, 0, -10)
        focuser.constraints = [SCNBillboardConstraint()]
        rootNode.addChildNode(focuser)
        
        startLocationService()
    }
    
    // MARK: Static Content Drawing
    
    private func drawStars() {
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.white
        mat.transparent.contents = #imageLiteral(resourceName: "star16x16")
        for star in stars {
            let radius = radiusForMagnitude(star.physicalInfo.magnitude)
            let plane = SCNPlane(width: radius, height: radius)
            plane.firstMaterial = mat
            let starNode = SCNNode(geometry: plane)
            let coord = star.physicalInfo.coordinate.normalized() * starLayerRadius
            starNode.constraints = [SCNBillboardConstraint()]
            starNode.position = SCNVector3(coord)
            starNode.name = String(star.identity.id)
            rootNode.addChildNode(starNode)
        }
    }
    
    private func drawConstellationLines() {
        let constellationLineNode = SCNNode()
        constellationLineNode.name = "constellation lines"
        rootNode.addChildNode(constellationLineNode)
        if Settings.default[.constellationLineMode] == .none { return }
        for con in Constellation.all {
            for line in con.connectionLines {
                var coord1 = line.star1.physicalInfo.coordinate.normalized() * starLayerRadius
                var coord2 = line.star2.physicalInfo.coordinate.normalized() * starLayerRadius
                let diff = coord2 - coord1
                coord1 = coord1 + diff * 0.05
                coord2 = coord2 - diff * 0.05
                let vertexSources = SCNGeometrySource(vertices: [coord1, coord2].map { SCNVector3($0) })
                let elements = SCNGeometryElement(indices: [CInt(0), CInt(1)], primitiveType: .line)
                let lineGeo = SCNGeometry(sources: [vertexSources], elements: [elements])
                let mat = SCNMaterial()
                mat.diffuse.contents = #colorLiteral(red: 0.7595454454, green: 0.89753443, blue: 0.859713316, alpha: 1).withAlphaComponent(0.3)
                lineGeo.firstMaterial = mat
                let lineNode = SCNNode(geometry: lineGeo)
                constellationLineNode.addChildNode(lineNode)
            }
        }
    }
    
    // MARK: Dynamic content drawing
    
    private func drawPlanetsAndMoon(ephemeris: Ephemeris) {
        ephemeris.forEach { (body) in
            guard rootNode.childNode(withName: String(body.naifId), recursively: false) == nil else { return }
            var diffuse: UIImage?
            switch body.naif {
            case let .majorBody(mb):
                switch mb {
                case .earth: return
                case .pluto:
                    diffuse = #imageLiteral(resourceName: "grey_planet_diffuse")
                case .mercury:
                    diffuse = #imageLiteral(resourceName: "orange_planet_diffuse")
                case .venus:
                    diffuse = #imageLiteral(resourceName: "yellow_planet_diffuse")
                case .jupiter:
                    diffuse = #imageLiteral(resourceName: "yellow_planet_diffuse")
                case .saturn:
                    diffuse = #imageLiteral(resourceName: "orange_planet_diffuse")
                case .mars:
                    diffuse = #imageLiteral(resourceName: "red_planet_diffuse")
                case .uranus:
                    diffuse = #imageLiteral(resourceName: "pale_blue_planet_diffuse")
                case .neptune:
                    diffuse = #imageLiteral(resourceName: "blue_planet_diffuse")
                }
                let planetNode = SCNNode(geometry: SCNPlane(width: 0.05, height: 0.05))
                planetNode.geometry?.firstMaterial?.isDoubleSided = true
                planetNode.geometry!.firstMaterial!.diffuse.contents = diffuse!
                planetNode.geometry!.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "planet_transparent")
                planetNode.name = String(body.naifId)
                rootNode.addChildNode(planetNode)
            case let .moon(m):
                if m == Naif.Moon.moon, let moonNode = largeBodyScene.rootNode.childNode(withName: "moon", recursively: true) {
                    moonNode.name = String(m.rawValue)
                    moonNode.categoryBitMask = Category.moon.rawValue
                    moonNode.removeFromParentNode()
                    rootNode.addChildNode(moonNode)
                }
            default:
                break
            }
        }
    }

    private func drawEcliptic(earth: CelestialBody) {
        func transform(position: Vector3) -> Vector3 {
            let rotated = position.oblique(by: earth.obliquity)
            return rotated.normalized() * auxillaryLineLayerRadius
        }
        eclipticNode?.removeFromParentNode()
        eclipticNode = EclipticLineNode(earth: earth, rawToModelCoordinateTransform: transform)
        rootNode.addChildNode(eclipticNode!)
    }

    private func drawCelestialEquator(earth: CelestialBody) {
        func transform(position: Vector3) -> Vector3 {
            return position.normalized() * auxillaryLineLayerRadius
        }
        celesitalEquatorNode?.removeFromParentNode()
        celesitalEquatorNode = CelestialEquatorLineNode(earth: earth, rawToModelCoordinateTransform: transform)
        rootNode.addChildNode(celesitalEquatorNode!)
    }
    
    private func drawAuxillaryLines(ephemeris: Ephemeris) {
        let earth = ephemeris[399]!
        drawEcliptic(earth: earth)
        drawCelestialEquator(earth: earth)
    }
    
    func updateGround(timestamp: Date? = nil) {
        if let t = timestamp {
            observerInfo?.timestamp = t
        }
        guard let transform = observerInfo?.localViewTransform else { return }
        let orientation = Quaternion(rotationMatrix: transform)
        debugNode.orientation = SCNQuaternion(orientation)
    }
    
    private func radiusForMagnitude(_ mag: Double, blendOutStart: Double = -0.5, blendOutEnd: Double = 5) -> CGFloat {
        let maxSize: Double = 0.28
        let minSize: Double = 0.01
        let linearEasing = Easing(startValue: maxSize, endValue: minSize)
        let progress = mag / (blendOutEnd - blendOutStart)
        return CGFloat(linearEasing.value(at: progress))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Focusing support
    
    func resetCamera() {
        cameraNode.transform = SCNMatrix4Identity
        (camera.xFov, camera.yFov) = (ObserverScene.defaultFov, ObserverScene.defaultFov)
        scale = 1
    }
    
    func focus(atNode node: SCNNode) {
        print(node)
    }
    
    // MARK: - Ephemeris Update Delegate
    func ephemerisDidLoad(ephemeris: Ephemeris) {
        drawAuxillaryLines(ephemeris: ephemeris)
        drawPlanetsAndMoon(ephemeris: ephemeris)
    }
    
    func ephemerisDidUpdate(ephemeris: Ephemeris) {
        updateGround(timestamp: ephemeris.timestamp)
        let earth = ephemeris[399]!
        let cbLabelNode = rootNode.childNode(withName: "celestialBodyAnnotations", recursively: false) ?? {
            let node = SCNNode()
            node.name = "celestialBodyAnnotations"
            rootNode.addChildNode(node)
            return node
        }()
        let zoomRatio = Double((sunNode.geometry as! SCNSphere).radius) / Sun.sol.radius
        let sunPos = -earth.heliocentricPosition
        let magnification: Double = 5
        let obliquedSunPos = sunPos.oblique(by: earth.obliquity)
        sunNode.position = SCNVector3(obliquedSunPos * zoomRatio / magnification)
        let earthPos = earth.heliocentricPosition
        annotateCelestialBody(Sun.sol, position: SCNVector3(obliquedSunPos), parent: cbLabelNode, class: .sunAndMoon)
        ephemeris.forEach { (body) in
            switch body.naif {
            case let .majorBody(mb):
                switch mb {
                case .earth: break
                default:
                    let planetRelativePos = (body.heliocentricPosition - earthPos).oblique(by: earth.obliquity)
                    if let planetNode = rootNode.childNode(withName: String(body.naifId), recursively: false) {
                        let position = SCNVector3(planetRelativePos.normalized() * planetLayerRadius)
                        planetNode.position = position
                        planetNode.constraints = [SCNBillboardConstraint()]
                        annotateCelestialBody(body, position: position, parent: cbLabelNode, class: .planet)
                    }
                }
            case let .moon(m):
                if m == Naif.Moon.moon {
                    guard let moonNode = rootNode.childNode(withName: String(m.rawValue), recursively: false) else { break }
                    let relativePos = body.motion?.position?.oblique(by: earth.obliquity) ?? Vector3.zero
                    let moonZoomRatio = Double((moonNode.geometry as! SCNSphere).radius) / body.radius
                    let position = SCNVector3(relativePos * moonZoomRatio / magnification)
                    moonNode.position = position
                    annotateCelestialBody(body, position: position, parent: cbLabelNode, class: .sunAndMoon)
                }
            default:
                break
            }
        }
    }
}

fileprivate extension Vector3 {
    func oblique(by obliquity: Double) -> Vector3 {
        // rotate around x-axis by earth's obliquity
        let m = Matrix4(rotation: Vector4(1, 0, 0, obliquity))
        return m * self
    }
}
