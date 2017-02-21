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

fileprivate let milkywayLayerRadius: Double = 50
fileprivate let auxillaryLineLayerRadius: Double = 25
fileprivate let starLayerRadius: Double = 20
fileprivate let planetLayerRadius: Double = 5

class ObserverScene: SCNScene, CameraControlling, FocusingSupport {
    
    lazy var stars = Star.magitudeLessThan(5.5)
    
    private lazy var camera: SCNCamera = {
        let c = SCNCamera()
        c.automaticallyAdjustsZRange = true
        c.xFov = defaultFov
        c.yFov = defaultFov
        return c
    }()
    
    lazy var cameraNode: SCNNode = {
        let cn = SCNNode()
        cn.camera = self.camera
        return cn
    }()
    
    var focusedNode: SCNNode?
    
    private var rotateByObliquity: ((Vector3) -> Vector3)? {
        guard let earth = self.earth else { return nil }
        func transform(position: Vector3) -> Vector3 {
            // rotate around y-axis by earth's obliquity
            let obliquity = earth.obliquity
            let q = Quaternion(0, 1, 0, -obliquity)
            return q * -position
        }
        return transform
    }
    
    private var earth: CelestialBody? {
        return self.ephemeris?[399]
    }
    
    var ephemeris: Ephemeris? {
        didSet {
            self.drawEcliptic()
            self.drawCelestialEquator()
            self.drawPlanets()
        }
    }
    
    static let defaultFov: Double = 45
    /// Determines how fast zooming changes fov; the greater this number, the faster
    private static let fovExpBase: Double = 1.25
    private static let maxFov: Double = 120
    private static let minFov: Double = 8
    // scale is inverse proportional to fov
    private static let maxScale: Double = exp2(log(defaultFov / minFov) / log(fovExpBase))
    private static var minScale: Double = exp2(log(defaultFov / maxFov) / log(fovExpBase))

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
    
    private lazy var milkyWayNode: SCNNode = {
        let scene = SCNScene(named: "stars.scnassets/celestial_sphere.scn")!
        let milkyWayNode = scene.rootNode.childNode(withName: "milky_way", recursively: true)!
        milkyWayNode.transform = SCNMatrix4Identity
        milkyWayNode.removeFromParentNode()
        let sphere = milkyWayNode.geometry as! SCNSphere
        sphere.firstMaterial!.cullMode = .front
        sphere.radius = CGFloat(milkywayLayerRadius)
        let mtx = SCNMatrix4MakeRotation(Float(-M_PI_2), 1, 0, 0)
        milkyWayNode.pivot = SCNMatrix4Scale(mtx, -1, 1, 1)
        milkyWayNode.opacity = 0.3
        return milkyWayNode
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
    
    override init() {
        super.init()
        resetCamera()
        rootNode.addChildNode(milkyWayNode)
        rootNode.addChildNode(sunNode)
        rootNode.addChildNode(cameraNode)
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
        drawConstellationLines()
        let southNode = SCNNode(geometry: SCNPlane(width: 0.1, height: 0.1))
        southNode.position = SCNVector3(0, 0, -10)
        southNode.geometry!.firstMaterial!.diffuse.contents = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        southNode.geometry!.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "annotation_cross")
        southNode.constraints = [SCNBillboardConstraint()]
        rootNode.addChildNode(southNode)
        let northNode = SCNNode(geometry: SCNPlane(width: 0.1, height: 0.1))
        northNode.position = SCNVector3(0, 0, 10)
        northNode.geometry!.firstMaterial!.diffuse.contents = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        northNode.geometry!.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "annotation_cross")
        northNode.constraints = [SCNBillboardConstraint()]
        rootNode.addChildNode(northNode)
    }
    
    private func drawPlanets() {
        ephemeris?.forEach { (body) in
            var diffuse: UIImage?
            guard case let .majorBody(mb) = body.naif else { return }
            switch mb {
            case .earth: return
            case .pluto: return
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
        }
    }
    
    private func drawLine(name: String, color: UIColor, transform: @escaping (Vector3) -> Vector3) {
        guard let earth = self.earth else { return }
        if let existingNode = rootNode.childNode(withName: name, recursively: false) {
            existingNode.removeFromParentNode()
        }
        let numberOfVertices: Int = 200
        let vertices: [SCNVector3] = Array(0..<numberOfVertices).map { index in
            let offset = Double(index) / Double(numberOfVertices) * M_PI * 2
            let (position, _) = earth.motion!.stateVectors(fromTrueAnomaly: offset)
            return SCNVector3(transform(-position))
        }
        let indices = (0...numberOfVertices).map { CInt($0 % numberOfVertices) }
        let vertexSources = SCNGeometrySource(vertices: vertices)
        let elements = SCNGeometryElement(indices: indices, primitiveType: .line)
        let line = SCNGeometry(sources: [vertexSources], elements: [elements])
        let lineNode = SCNNode(geometry: line)
        lineNode.name = name
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        line.firstMaterial = mat
        rootNode.addChildNode(lineNode)
    }
    
    private func drawConstellationLines() {
        let connectionNode = SCNNode()
        rootNode.addChildNode(connectionNode)
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
                mat.diffuse.contents = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                lineGeo.firstMaterial = mat
                let lineNode = SCNNode(geometry: lineGeo)
                connectionNode.addChildNode(lineNode)
            }
        }
    }
    
    private func drawEcliptic() {
        func transform(position: Vector3) -> Vector3 {
            let rotated = position.oblique(by: earth!.obliquity)
            return rotated.normalized() * auxillaryLineLayerRadius
        }
        if Settings.default[.showEcliptic] {
            drawLine(name: "ecliptic line", color: Settings.default[.eclipticColor], transform: transform)
        }
    }
    
    private func drawCelestialEquator() {
        func transform(position: Vector3) -> Vector3 {
            return position.normalized() * auxillaryLineLayerRadius
        }
        if Settings.default[.showCelestialEquator] {
            drawLine(name: "celestial equator line", color: Settings.default[.celestialEquatorColor], transform: transform)
        }
    }
    
    func updateEphemeris() {
        guard let eph = self.ephemeris else { return }
        eph.updateMotion()
        let zoomRatio = Double((sunNode.geometry as! SCNSphere).radius) / (Sun.sol.radius * 1000)
        let sunPos = -earth!.heliocentricPosition
        let magnification: Double = 5
        let obliquedSunPos = sunPos.oblique(by: earth!.obliquity)
        sunNode.position = SCNVector3(obliquedSunPos * zoomRatio / magnification)
        let earthPos = earth!.heliocentricPosition
        ephemeris?.forEach { (body) in
            guard case let .majorBody(mb) = body.naif else { return }
            switch mb {
            case .earth: break
            default:
                let planetRelativePos = (body.heliocentricPosition - earthPos).oblique(by: earth!.obliquity)
                if let planetNode = rootNode.childNode(withName: String(body.naifId), recursively: false) {
                    planetNode.position = SCNVector3(planetRelativePos.normalized() * planetLayerRadius)
                    planetNode.constraints = [SCNBillboardConstraint()]
                }
            }
        }
    }
    
    func resetCamera() {
        cameraNode.transform = SCNMatrix4Identity
        (camera.xFov, camera.yFov) = (ObserverScene.defaultFov, ObserverScene.defaultFov)
        scale = 1
    }
    
    func focus(atNode node: SCNNode) {
        
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
}

fileprivate extension Vector3 {
    func oblique(by obliquity: Double) -> Vector3 {
        // rotate around x-axis by earth's obliquity
        let m = Matrix4(rotation: Vector4(1, 0, 0, obliquity))
        return m * self
    }
}
