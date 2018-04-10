//
//  SolarSystemScene.swift
//  Graviton
//
//  Created by Ben Lu on 10/30/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import SpaceTime
import MathUtil

class SolarSystemScene: SCNScene, CameraResponsive, FocusingSupport {

    private static let orbitLineShader: String = {
        let path = Bundle.main.path(forResource: "orbit_line.surface", ofType: "shader")!
        return try! String(contentsOfFile: path, encoding: .utf8)
    }()
    private static let baseOrthographicScale: Double = 25
    private static let maxScale: Double = 100
    private static let minScale: Double = 0.02
    private static let diminishStartDistance: Float = 3.3
    private static let diminishEndDistance: Float = 1.8
    private static let sunNodeSize: CGFloat = 0.9
    private static let planetNodeSize: CGFloat = 0.7

    var gestureOrientation: Quaternion {
        return Quaternion.identity
    }

    private var orbitalMotions = [(OrbitalMotion, UIColor, Int)]()
    private var lineSegments = SCNNode()
    var spheres = SCNNode()
    var celestialBodies: [CelestialBody] = []

    var focusedNode: SCNNode?
    var focusedBody: CelestialBody? {
        guard let n = focusedNode else { return nil }
        return celestialBodies.filter { $0.naifId == Int(n.name!)! }.first
    }

    var julianDay: JulianDay = JulianDay.J2000 {
        didSet {
            orbitalMotions.forEach { [weak self] (motion, color, identifier) in
                self?.drawOrbitalMotion(motion: motion, color: color, identifier: identifier)
            }
        }
    }

    var scale: Double = 1 {
        didSet {
            let cappedScale = min(max(scale, SolarSystemScene.minScale), SolarSystemScene.maxScale)
            self.scale = cappedScale
            self.camera.orthographicScale = SolarSystemScene.baseOrthographicScale / cappedScale
            // keep the spheres the same size
            (spheres.childNodes + [sunNode]).forEach { (sphere) in
                // radius default is 1
                let s = 1.0 / cappedScale
                sphere.scale = SCNVector3(s, s, s)
            }

            spheres.childNodes.forEach { (sphere) in
                let apparentDist = (sphere.position * Float(cappedScale)).distance(sunNode.position * Float(cappedScale))
                let ds = SolarSystemScene.diminishStartDistance
                let de = SolarSystemScene.diminishEndDistance
                let f = CGFloat((max(min(ds, apparentDist), de) - de) / (ds - de))
                sphere.opacity = f
                if let orbit = lineSegments.childNode(withName: orbitIdentifier(sphere.name!), recursively: false) {
                    orbit.opacity = f
                }
            }
        }
    }

    private lazy var camera: SCNCamera = {
        let c = SCNCamera()
        c.usesOrthographicProjection = true
        c.automaticallyAdjustsZRange = true
        c.orthographicScale = SolarSystemScene.baseOrthographicScale * self.scale
        return c
    }()

    private lazy var sunNode: SCNNode = {
        let sun = SCNNode(geometry: SCNSphere(radius: SolarSystemScene.sunNodeSize))
        sun.name = String(Naif.sun.rawValue)
        sun.geometry!.firstMaterial = {
            let mat = SCNMaterial()
            mat.emission.contents = UIColor.white
            return mat
        }()
        sun.light = SCNLight()
        sun.light!.type = .omni
        return sun
    }()

    lazy private(set) var cameraNode: SCNNode = {
        let node = SCNNode()
        node.camera = self.camera
        self.applyCameraNodeDefaultSettings(cameraNode: node)
        return node
    }()

    private func generateOrbitLineMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.shaderModifiers = [.surface: SolarSystemScene.orbitLineShader]
        return material
    }

    override init() {
        super.init()
        focusedNode = sunNode
        rootNode.addChildNode(sunNode)
        rootNode.addChildNode(cameraNode)
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light?.intensity = 500
        rootNode.addChildNode(ambient)
        rootNode.addChildNode(lineSegments)
        rootNode.addChildNode(spheres)
        celestialBodies.append(Sun.sol)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func ephemerisDidLoad(ephemeris: Ephemeris) {
        clearScene()
        let colors: [Int: UIColor] = [
            199: #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1),
            299: #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1),
            399: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1),
            499: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1),
            599: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1),
            699: #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1),
            799: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1),
            899: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),
            999: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        ]
        ephemeris.forEach { [weak self] (body) in
            if let color = colors[body.naifId] {
                self?.add(body: body, color: color)
            }
        }
    }

    func ephemerisDidUpdate(ephemeris: Ephemeris) {

    }

    func add(body: CelestialBody, color: UIColor) {
        celestialBodies.append(body)
        orbitalMotions.append((body.motion!, color, body.naifId))
        drawOrbitalMotion(motion: body.motion!, color: color, identifier: body.naifId)
    }

    private func applyCameraNodeDefaultSettings(cameraNode: SCNNode) {
        cameraNode.position = SCNVector3()
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, 0, -100000)
        cameraNode.rotation = SCNVector4()
        scale = 1
    }

    func resetCamera() {
        camera.orthographicScale = 40
        applyCameraNodeDefaultSettings(cameraNode: cameraNode)
    }

    func focus(atNode node: SCNNode) {
        if node != focusedNode {
            cameraNode.position = node.position
        }
        focusedNode = node
    }

    func clearScene() {
        spheres.childNodes.forEach { $0.removeFromParentNode() }
        lineSegments.childNodes.forEach { $0.removeFromParentNode() }
        orbitalMotions.removeAll()
    }

    private func drawOrbitalMotion(motion: OrbitalMotion, color: UIColor, identifier: Int) {
        motion.julianDay = julianDay
        if let planetNode = spheres.childNode(withName: String(identifier), recursively: false) {
            planetNode.position = zoom(position: motion.position)
        } else {
            let sphere = SCNSphere(radius: SolarSystemScene.planetNodeSize)
            sphere.firstMaterial = {
                let mat = SCNMaterial()
                mat.diffuse.contents = color
                return mat
            }()
            let planetNode = SCNNode(geometry: sphere)
            planetNode.name = String(identifier)
            planetNode.position = zoom(position: motion.position)
            spheres.addChildNode(planetNode)
        }

        func addNode(identifier: String) -> SCNNode {
            let numberOfVertices: Int = 100
            let vertices = (0..<numberOfVertices).map { index -> SCNVector3 in
                let offset = Double(index) / Double(numberOfVertices) * Double.pi * 2
                return zoom(position: motion.unrotatedStateVectors(fromTrueAnomaly: offset).0)
            }
            var indices = [CInt]()
            for i in 0..<(numberOfVertices - 1) {
                indices.append(CInt(i))
                indices.append(CInt(i + 1))
            }
            indices.append(CInt(numberOfVertices - 1))
            indices.append(CInt(0))
            let vertexSources = SCNGeometrySource(vertices: vertices)
            let elements = SCNGeometryElement(indices: indices, primitiveType: .line)
            let line = SCNGeometry(sources: [vertexSources], elements: [elements])
            let lineNode = SCNNode(geometry: line)
            lineNode.transform = SCNMatrix4(Matrix4(quaternion: motion.orbit.orientationTransform))
            lineNode.name = identifier
            line.firstMaterial = generateOrbitLineMaterial(color: color)
            lineSegments.addChildNode(lineNode)
            logger.info("create \(identifier): \(motion.orbit)")
            return lineNode
        }
        let lineNode = lineSegments.childNode(withName: orbitIdentifier(identifier), recursively: false) ?? addNode(identifier: orbitIdentifier(identifier))
        lineNode.geometry?.firstMaterial?.setValue(motion.trueAnomaly, forKeyPath: "trueAnomaly")
        lineNode.geometry?.firstMaterial?.setValue(0.05, forKeyPath: "transparentStart")
        lineNode.geometry?.firstMaterial?.setValue(0.7, forKeyPath: "transparentEnd")
    }

    private func zoom(position: Vector3) -> SCNVector3 {
        return SCNVector3(position / astronomicalUnitDist * 10)
    }
}

private func orbitIdentifier(_ identifier: Int) -> String {
    return "\(identifier)_orbit"
}

private func orbitIdentifier(_ identifier: String) -> String {
    return "\(identifier)_orbit"
}
