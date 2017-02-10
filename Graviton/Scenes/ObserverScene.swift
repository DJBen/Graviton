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
import SpaceTime
import MathUtil

class ObserverScene: SCNScene, CameraControlling, FocusingSupport {
    
    lazy var stars = DistantStar.magitudeLessThan(5)
    
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
        sphere.radius = 50
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
        return SCNNode(geometry: sphere)
    }()
    
    private func makePlanet(naifId: Int, color: UIColor) -> SCNNode {
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        let sphere = SCNSphere(radius: 0.1)
        sphere.firstMaterial = mat
        let node = SCNNode(geometry: sphere)
        node.name = String(naifId)
        return node
    }
    
    override init() {
        super.init()
        resetCamera()
        rootNode.addChildNode(milkyWayNode)
        rootNode.addChildNode(sunNode)
        rootNode.addChildNode(cameraNode)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.white
        mat.transparent.contents = #imageLiteral(resourceName: "star16x16")
        mat.isDoubleSided = true
        for star in stars {
            let radius = radiusForMagnitude(star.physicalInfo.magnitude)
            let plane = SCNPlane(width: radius, height: radius)
            plane.firstMaterial = mat
            let starNode = SCNNode(geometry: plane)
            let coord = star.physicalInfo.coordinate.normalized() * 10
            starNode.constraints = [SCNBillboardConstraint()]
            starNode.position = SCNVector3(coord)
            starNode.name = String(star.identity.id)
            rootNode.addChildNode(starNode)
        }
        let southNode = SCNNode(geometry: SCNSphere(radius: 0.1))
        southNode.position = SCNVector3(0, 0, -10)
        southNode.geometry!.firstMaterial!.diffuse.contents = UIColor.red
        rootNode.addChildNode(southNode)
        let northNode = SCNNode(geometry: SCNSphere(radius: 0.1))
        northNode.position = SCNVector3(0, 0, 10)
        northNode.geometry!.firstMaterial!.diffuse.contents = UIColor.blue
        rootNode.addChildNode(northNode)
        let yNode = SCNNode(geometry: SCNSphere(radius: 0.1))
        yNode.geometry!.firstMaterial!.diffuse.contents = UIColor.purple
        yNode.position = SCNVector3(0, 10, 0)
        rootNode.addChildNode(yNode)
        let xNode = SCNNode(geometry: SCNSphere(radius: 0.1))
        xNode.geometry!.firstMaterial!.diffuse.contents = UIColor.green
        xNode.position = SCNVector3(10, 0, 0)
        rootNode.addChildNode(xNode)
    }
    
    func drawLine(name: String, color: UIColor, transform: @escaping (Vector3) -> Vector3) {
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
    
    func drawEcliptic() {
        func transform(position: Vector3) -> Vector3 {
            let rotated = position.oblique(by: earth!.obliquity)
            return rotated.normalized() * 25
        }
        drawLine(name: "ecliptic line", color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), transform: transform)
    }
    
    func drawCelestialEquator() {
        func transform(position: Vector3) -> Vector3 {
            return position.normalized() * 25
        }
        drawLine(name: "celestial equator line", color: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), transform: transform)
    }
    
    func updateEphemeris() {
        guard let eph = self.ephemeris else { return }
        eph.updateMotion()
        let zoomRatio = Double((sunNode.geometry as! SCNSphere).radius) / (Star.sun.radius * 1000)
        let sunPos = -earth!.heliocentricPosition
        let magnification: Double = 5
        let obliquedSunPos = sunPos.oblique(by: earth!.obliquity)
        sunNode.position = SCNVector3(obliquedSunPos * zoomRatio / magnification)
    }
    
    func resetCamera() {
        cameraNode.transform = SCNMatrix4Identity
        (camera.xFov, camera.yFov) = (ObserverScene.defaultFov, ObserverScene.defaultFov)
        scale = 1
    }
    
    func focus(atNode node: SCNNode) {
        
    }
    
    private func radiusForMagnitude(_ mag: Double, blendOutStart: Double = 0, blendOutEnd: Double = 5) -> CGFloat {
        let maxSize: Double = 0.1
        let minSize: Double = 0.02
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
