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
fileprivate let planetLayerRadius: Double = 10
fileprivate let landscapeLayerRadius: Double = 6
fileprivate let compassRoseRadius: Double = 5.5
fileprivate let directionMarkerLayerRadius: Double = 5.5
fileprivate let moonLayerRadius: Double = 7
fileprivate let sunLayerRadius: Double = 8
fileprivate let largeBodyScene = SCNScene(named: "art.scnassets/large_bodies.scn")!

class ObserverScene: SCNScene, CameraResponsive, FocusingSupport {

    struct VisibilityCategory: OptionSet {
        let rawValue: Int
        static let none = VisibilityCategory(rawValue: 0)
        /// All non-moon objects
        static let nonMoon = VisibilityCategory(rawValue: 1)
        /// The moon and its associated lighting
        static let moon = VisibilityCategory(rawValue: 1 << 1)
        /// Camera having the visibility of everything except none
        static let camera: VisibilityCategory = VisibilityCategory(rawValue: ~0)
    }

    static let defaultFov: Double = 45
    /// Determines how fast zooming changes fov; the greater this number, the faster
    private static let fovExpBase: Double = 1.25
    private static let maxFov: Double = 120
    private static let minFov: Double = 8
    // scale is inverse proportional to fov
    private static let maxScale: Double = exp2(log(defaultFov / minFov) / log(fovExpBase))
    private static var minScale: Double = exp2(log(defaultFov / maxFov) / log(fovExpBase))

    /// Maximum magnification for the Sun and the Moon
    private static let maxMagnification: Double = 15

    var motionSubscriptionId: SubscriptionUUID?

    var gestureOrientation: Quaternion = Quaternion.identity

    lazy var stars = Star.magitudeLessThan(5.3)

    private lazy var camera: SCNCamera = {
        let camera = SCNCamera()
        camera.zNear = 0.5
        camera.zFar = 1000
        camera.xFov = defaultFov
        camera.yFov = defaultFov
        camera.categoryBitMask = VisibilityCategory.camera.rawValue
        return camera
    }()

    lazy var cameraNode: SCNNode = {
        let cn = SCNNode()
        cn.camera = self.camera
        let quaternion = Quaternion(axisAngle: Vector4(0, 1, 0, Double.pi / 2)) * Quaternion(axisAngle: Vector4(1, 0, 0, -Double.pi / 2))
        cn.pivot = SCNMatrix4(Matrix4(quaternion: quaternion))
        return cn
    }()

    var focusedNode: SCNNode?

    var scale: Double = 1 {
        didSet {
            let cappedScale = min(max(scale, ObserverScene.minScale), ObserverScene.maxScale)
            self.scale = cappedScale
            self.camera.xFov = self.fov
            self.camera.yFov = self.fov
            updateForZoomChanges()
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

    private var dynamicMagnificationFactor: Double {
        let easing = Easing.init(startValue: 1, endValue: ObserverScene.maxMagnification)
        let fovPercentage = (fov - ObserverScene.minFov) / (ObserverScene.maxFov - ObserverScene.minFov)
        return easing.value(at: fovPercentage)
    }

    var observerInfo: LocationAndTime?

    // MARK: - Property - Visual Nodes

    private var celestialEquatorNode: CelestialEquatorLineNode?
    private var eclipticNode: EclipticLineNode?

    private lazy var milkyWayNode: SCNNode = {
        let node = SphereInteriorNode.init(radius: milkywayLayerRadius, textureLongitudeOffset: -Double.pi / 2)
        node.sphere.firstMaterial!.diffuse.contents = #imageLiteral(resourceName: "milkyway.png")
        node.sphere.firstMaterial!.locksAmbientWithDiffuse = true
        node.opacity = 0.3
        node.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        return node
    }()

    lazy var panoramaNode: SCNNode = {
        let node = SphereInteriorNode(radius: landscapeLayerRadius)
        node.sphere.firstMaterial!.diffuse.contents = UIColor.white
        node.sphere.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "debug_sphere_directions_transparency")
        // since the coordinate is NED, we rotate around center by 180 degrees to make it upside down
        var mtx = SCNMatrix4MakeTranslation(-0.5, -0.5, 0)
        mtx = SCNMatrix4Rotate(mtx, Float(Double.pi), 0, 0, 1)
        mtx = SCNMatrix4Translate(mtx, 0.5, 0.5, 0)
        node.sphere.firstMaterial!.transparent.contentsTransform = mtx
        node.sphere.firstMaterial!.isDoubleSided = true
        node.sphere.firstMaterial!.locksAmbientWithDiffuse = true
        node.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        return node
    }()

    lazy var sunNode: SCNNode = {
        let sunMat = SCNMaterial()
        sunMat.diffuse.contents = #imageLiteral(resourceName: "sun")
        sunMat.locksAmbientWithDiffuse = true
        let sphere = SCNSphere(radius: 0.0)
        sphere.firstMaterial = sunMat
        let node = SCNNode(geometry: sphere)
        node.name = String(Sun.sol.naifId)
        node.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        return node
    }()

    lazy var defaultLightingNode: SCNNode = {
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 700
        light.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        let node = SCNNode()
        node.light = light
        node.name = "default lighting"
        return node
    }()

    lazy var moonEarthshineNode: SCNNode = {
        let light = BooleanFlaggedLight.init(setting: .showEarthshine, on: { (light) in
            light.type = .omni
            light.categoryBitMask = VisibilityCategory.moon.rawValue
        }, off: { (light) in
            light.categoryBitMask = VisibilityCategory.none.rawValue
        })
        let node = SCNNode()
        node.light = light
        node.name = "earthshine"
        return node
    }()

    lazy var moonLightingNode: SCNNode = {
        let light = BooleanFlaggedLight.init(setting: .showMoonPhase, on: { (light) in
            light.intensity = 1000
        }, off: { (light) in
            light.intensity = 0
        })
        light.type = .omni
        light.categoryBitMask = VisibilityCategory.moon.rawValue
        let node = SCNNode()
        node.light = light
        node.name = "moon lighting"
        return node
    }()

    lazy var moonFullLightingNode: SCNNode = {
        let light = BooleanFlaggedLight.init(setting: .showMoonPhase, on: { (light) in
            light.intensity = 0
        }, off: { (light) in
            light.intensity = 1000
        })
        light.type = .omni
        light.categoryBitMask = VisibilityCategory.moon.rawValue
        let node = SCNNode()
        node.light = light
        node.name = "moon full lighting"
        return node
    }()

    lazy var moonNode: SCNNode = {
        let moonMat = SCNMaterial()
        // material without normal is better in observer view
        moonMat.diffuse.contents = #imageLiteral(resourceName: "moon.jpg")
        moonMat.ambient.contents = UIColor.black
        moonMat.locksAmbientWithDiffuse = false
        // radius will be set later
        let sphere = SCNSphere(radius: 0.0)
        sphere.firstMaterial = moonMat
        let node = SCNNode(geometry: sphere)
        node.name = String(301)
        node.categoryBitMask = VisibilityCategory.moon.rawValue
        node.pivot = SCNMatrix4(
            Matrix4(rotation: Vector4(0, 1, 0, Double.pi / 2)) *
            Matrix4(rotation: Vector4(1, 0, 0, -Double.pi / 2))
        )
        return node
    }()

    lazy var compassRoseNode: CompassRoseNode = CompassRoseNode(radius: 5.5, sideLength: 0.8)

    lazy var directionMarkers = DirectionMarkerNode(radius: directionMarkerLayerRadius, sideLength: 0.3)
    var jumpToCelestialPointObserver: NSObjectProtocol!
    var jumpToDirectionObserver: NSObjectProtocol!

    override init() {
        super.init()
        resetCamera()
        rootNode.addChildNode(defaultLightingNode)
        rootNode.addChildNode(milkyWayNode)
        rootNode.addChildNode(panoramaNode)
        rootNode.addChildNode(sunNode)
        rootNode.addChildNode(cameraNode)
        rootNode.addChildNode(directionMarkers)
        rootNode.addChildNode(compassRoseNode)
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
        focuser.categoryBitMask = VisibilityCategory.nonMoon.rawValue
        rootNode.addChildNode(focuser)

        jumpToCelestialPointObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "jumpToCelestialPoint"), object: nil, queue: OperationQueue.main) { (notification) in
            guard let coordinate = notification.userInfo?["content"] as? EquatorialCoordinate else {
                return
            }
            self.cameraNode.orientation = SCNQuaternion(Quaternion(alignVector: Vector3(1, 0, 0), with: Vector3(equatorialCoordinate: coordinate)))
        }
        jumpToDirectionObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "jumpToDirection"), object: nil, queue: OperationQueue.main) { (notification) in
            guard let coordinate = notification.userInfo?["content"] as? HorizontalCoordinate else {
                return
            }
            guard let obInfo = self.observerInfo else {
                print("Missing observer info")
                return
            }
            self.cameraNode.orientation = SCNQuaternion(Quaternion(alignVector: Vector3(1, 0, 0), with: Vector3(equatorialCoordinate: EquatorialCoordinate(horizontalCoordinate: coordinate, observerInfo: obInfo))))
        }

        loadPanoramaTexture(Settings.default[.groundTexture])
        Settings.default.subscribe(setting: .groundTexture, object: self) { (_, newValue) in
            self.loadPanoramaTexture(newValue)
        }
    }

    private func loadPanoramaTexture(_ key: String) {
        self.panoramaNode.isHidden = key == "none"
        switch key {
        case "citySilhoulette":
            self.panoramaNode.geometry?.firstMaterial?.transparent.contents = #imageLiteral(resourceName: "panorama_city_silhoulette")
            self.panoramaNode.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.3)
        case "debugNode":
            self.panoramaNode.geometry?.firstMaterial?.transparent.contents = #imageLiteral(resourceName: "debug_sphere_directions_transparency")
            self.panoramaNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        case "none":
            break
        default:
            fatalError("unrecognized groundTexture setting")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(jumpToCelestialPointObserver)
        NotificationCenter.default.removeObserver(jumpToDirectionObserver)
    }

    // MARK: Static Content Drawing

    private func drawStars() {
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.white
        mat.transparent.contents = #imageLiteral(resourceName: "star16x16")
        mat.locksAmbientWithDiffuse = true
        for star in stars {
            let radius = radiusForMagnitude(star.physicalInfo.magnitude)
            let plane = SCNPlane(width: radius, height: radius)
            plane.firstMaterial = mat
            let starNode = SCNNode(geometry: plane)
            let coord = star.physicalInfo.coordinate.normalized() * starLayerRadius
            starNode.constraints = [SCNBillboardConstraint()]
            starNode.position = SCNVector3(coord)
            starNode.name = String(star.identity.id)
            starNode.categoryBitMask = VisibilityCategory.nonMoon.rawValue
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
                mat.locksAmbientWithDiffuse = true
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
                let planetNode = SCNNode(geometry: SCNPlane(width: 0.1, height: 0.1))
                planetNode.geometry?.firstMaterial?.isDoubleSided = true
                planetNode.geometry!.firstMaterial!.diffuse.contents = diffuse!
                planetNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
                planetNode.geometry!.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "planet_transparent")
                planetNode.name = String(body.naifId)
                planetNode.categoryBitMask = VisibilityCategory.nonMoon.rawValue
                rootNode.addChildNode(planetNode)
            case let .moon(m):
                if m == Naif.Moon.luna, moonNode.parent == nil {
                    rootNode.addChildNode(moonNode)
                    rootNode.addChildNode(moonLightingNode)
                    rootNode.addChildNode(moonEarthshineNode)
                    rootNode.addChildNode(moonFullLightingNode)
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
        celestialEquatorNode?.removeFromParentNode()
        celestialEquatorNode = CelestialEquatorLineNode(earth: earth, rawToModelCoordinateTransform: transform)
        rootNode.addChildNode(celestialEquatorNode!)
    }

    private func drawAuxillaryLines(ephemeris: Ephemeris) {
        let earth = ephemeris[399]!
        drawEcliptic(earth: earth)
        drawCelestialEquator(earth: earth)
    }

    func updateObserverView(timestamp: JulianDate? = nil) {
        if let t = timestamp {
            observerInfo?.timestamp = t
        }
        guard let transform = observerInfo?.localViewTransform else { return }
        let orientation = Quaternion(rotationMatrix: transform)
        panoramaNode.orientation = SCNQuaternion(orientation)
        directionMarkers.ecefToNedOrientation = orientation
        compassRoseNode.ecefToNedOrientation = orientation
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

    private func updateForZoomChanges() {
        if let id = motionSubscriptionId, let ephemeris = EphemerisMotionManager.default.content(for: id) {
            updateDynamicSizes(forEphemeris: ephemeris)
        }
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

    // MARK: - Observer Ephemeris Update
    func observerInfoUpdate(observerInfo: [Naif: CelestialBodyObserverInfo]) {
        if observerInfo[.moon(.luna)] != nil {
            updateMoonOrientation()
        }
        print(observerInfo)
    }

    private func updateMoonOrientation() {
        guard let moonInfo = ObserverEphemerisManager.default.content?[.moon(.luna)] else {
            return
        }
        let position = Vector3(moonNode.position)
        let moonEquatorialCoord = EquatorialCoordinate(cartesian: position)
        let obLonRad = radians(degrees: moonInfo.obLon)
        let obLatRad = radians(degrees: moonInfo.obLat)
        let moonPoleAxis = Vector3(equatorialCoordinate: EquatorialCoordinate(rightAscension: radians(degrees: moonInfo.npRa), declination: radians(degrees: moonInfo.npDec), distance: 1))
        let raRot = Quaternion(axisAngle: Vector4(0, 0, 1, moonEquatorialCoord.rightAscension - obLonRad))
        let decRotAxis = Vector3(position.x, -position.y, 0).normalized()
        let decRot = Quaternion(axisAngle: Vector4(decRotAxis, w: moonEquatorialCoord.declination - obLatRad))
        let rotatedAxis = raRot * decRot * moonPoleAxis
        let parallanticAngleRot = Quaternion.init(alignVector: decRot * Vector3(0, 0, 1), with: rotatedAxis)
        let moonOrientation = parallanticAngleRot * raRot * decRot
        precondition(moonOrientation.length ~= 1, "quaternion should have unit length")
        moonNode.orientation = SCNQuaternion(moonOrientation)
    }

    // MARK: - Location Update
    func updateLocationAndTime(observerInfo: LocationAndTime) {
        self.observerInfo = observerInfo
        updateObserverView()
    }

    // MARK: - Ephemeris Update
    private func updateDynamicSizes(forEphemeris ephemeris: Ephemeris) {
        if let earth = ephemeris[.majorBody(.earth)], let earthPos = earth.position {
            let sunPos = -earthPos
            let sunDisplaySize = Sun.sol.radius * sunLayerRadius / sunPos.length
            (sunNode.geometry as! SCNSphere).radius = CGFloat(sunDisplaySize * dynamicMagnificationFactor)
        }
        if let moonBody = ephemeris[.moon(.luna)], let relativePos = moonBody.motion?.position {
            let moonDisplaySize = moonBody.radius * moonLayerRadius / relativePos.length
            (moonNode.geometry as! SCNSphere).radius = CGFloat(moonDisplaySize * dynamicMagnificationFactor)
        }
    }

    func ephemerisDidLoad(ephemeris: Ephemeris) {
        drawAuxillaryLines(ephemeris: ephemeris)
        drawPlanetsAndMoon(ephemeris: ephemeris)
    }

    func ephemerisDidUpdate(ephemeris: Ephemeris) {
        print("update ephemeris at \(String(describing: ephemeris.timestamp)) using data at \(String(describing: ephemeris.referenceTimestamp))")
        updateObserverView(timestamp: ephemeris.timestamp)
        let earth = ephemeris[399]!
        let cbLabelNode = rootNode.childNode(withName: "celestialBodyAnnotations", recursively: false) ?? {
            let node = SCNNode()
            node.name = "celestialBodyAnnotations"
            rootNode.addChildNode(node)
            return node
        }()
        let sunPos = -earth.position!
        // The should-be radius of the sun being displayed at a certain distance from camera
        let sunDisplaySize = Sun.sol.radius * sunLayerRadius / sunPos.length
        let zoomRatio = sunDisplaySize / Sun.sol.radius
        (sunNode.geometry as! SCNSphere).radius = CGFloat(sunDisplaySize * dynamicMagnificationFactor)
        let obliquedSunPos = sunPos.oblique(by: earth.obliquity)
        let sunDisplayPosition = obliquedSunPos * zoomRatio
        precondition(sunDisplayPosition.length ~= sunLayerRadius)
        sunNode.position = SCNVector3(sunDisplayPosition)
        sunNode.constraints = [SCNBillboardConstraint()]
        let earthPos = earth.position!
        annotateCelestialBody(Sun.sol, position: SCNVector3(obliquedSunPos), parent: cbLabelNode, class: .sunAndMoon)
        ephemeris.forEach { (body) in
            switch body.naif {
            case let .majorBody(mb):
                switch mb {
                case .earth: break
                default:
                    let planetRelativePos = (body.position! - earthPos).oblique(by: earth.obliquity)
                    if let planetNode = rootNode.childNode(withName: String(body.naifId), recursively: false) {
                        let position = SCNVector3(planetRelativePos.normalized() * planetLayerRadius)
                        planetNode.position = position
                        planetNode.constraints = [SCNBillboardConstraint()]
                        annotateCelestialBody(body, position: position, parent: cbLabelNode, class: .planet)
                    }
                }
            case let .moon(m):
                if m == Naif.Moon.luna {
                    guard let moonNode = rootNode.childNode(withName: String(m.rawValue), recursively: false) else { break }
                    let relativePos = body.motion?.position ?? Vector3.zero
                    let moonDisplaySize = body.radius * moonLayerRadius / relativePos.length
                    let moonZoomRatio = moonDisplaySize / body.radius
                    (moonNode.geometry as! SCNSphere).radius = CGFloat(moonDisplaySize * dynamicMagnificationFactor)
                    let moonPosition = relativePos * moonZoomRatio
                    let obliquedMoonPos = moonPosition.oblique(by: earth.obliquity)
                    precondition(obliquedMoonPos.length ~= moonLayerRadius)
                    annotateCelestialBody(body, position: SCNVector3(obliquedMoonPos), parent: cbLabelNode, class: .sunAndMoon)
                    moonNode.position = SCNVector3(obliquedMoonPos)
                    let hypotheticalSunPos = obliquedSunPos * moonZoomRatio / dynamicMagnificationFactor
                    moonLightingNode.position = SCNVector3(hypotheticalSunPos)
                    moonEarthshineNode.position = SCNVector3Zero
                    moonFullLightingNode.position = SCNVector3Zero
                    let cosAngle = hypotheticalSunPos.normalized().dot(-obliquedMoonPos.normalized())
                    print("earth-sun-moon cos(angle): \(cosAngle)")
                    moonEarthshineNode.light?.intensity = CGFloat(max(-cosAngle, 0) * 80)
                    updateMoonOrientation()
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
