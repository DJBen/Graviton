//
//  SolScene.swift
//  Graviton
//
//  Created by Ben Lu on 10/30/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import SpaceTime

fileprivate let astronomicalUnitDist: Float = 1.4960e11

protocol CameraControlling {
    var cameraNode: SCNNode { get }
    var scale: Double { get set }
    func resetCamera()
}

class SolScene: SCNScene, CameraControlling {
    
    private static let baseOrthographicScale: Double = 15
    private static let maxScale: Double = 5
    private static let minScale: Double = 0.02
    
    private var orbitalMotions = [(OrbitalMotion, UIColor, String)]()
    private var lineSegments = SCNNode()
    private var spheres = SCNNode()
    
    var julianDate: Float = Float(JulianDate.J2000) {
        didSet {
            orbitalMotions.forEach { (motion, color, identifier) in
                self.drawOrbitalMotion(motion: motion, color: color, identifier: identifier)
            }
        }
    }
    
    var scale: Double = 1 {
        didSet {
            let cappedScale = min(max(scale, SolScene.minScale), SolScene.maxScale)
            self.scale = cappedScale
            self.camera.orthographicScale = SolScene.baseOrthographicScale / cappedScale
            // keep the spheres the same size
            (spheres.childNodes + [sunNode]).forEach { (sphere) in
                // radius default is 1
                let s = 1.0 / cappedScale
                sphere.scale = SCNVector3(s, s, s)
            }
            
            spheres.childNodes.forEach { (sphere) in
                let apparentDist = (sphere.position * Float(cappedScale)).distance(sunNode.position * Float(cappedScale))
                let f = CGFloat(max(min(3, apparentDist), 1.5) - 1.5) / (3 - 1.5)
                sphere.opacity = f
                if let orbit = lineSegments.childNode(withName: sphere.name!, recursively: false) {
                    orbit.opacity = f
                }
            }
        }
    }
    
    private lazy var camera: SCNCamera = {
        let c = SCNCamera()
        c.usesOrthographicProjection = true
        c.automaticallyAdjustsZRange = true
        c.orthographicScale = SolScene.baseOrthographicScale * self.scale
        return c
    }()
    
    private lazy var sunNode: SCNNode = {
        let sun = SCNNode(geometry: SCNSphere(radius: 0.9))
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
    
    override init() {
        super.init()
        rootNode.addChildNode(sunNode)
        rootNode.addChildNode(cameraNode)
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light?.intensity = 500
        rootNode.addChildNode(ambient)
        rootNode.addChildNode(lineSegments)
        rootNode.addChildNode(spheres)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addOrbitalMotion(motion: OrbitalMotion, color: UIColor, identifier: String) {
        orbitalMotions.append((motion, color, identifier))
        drawOrbitalMotion(motion: motion, color: color, identifier: identifier)
    }
    
    private func applyCameraNodeDefaultSettings(cameraNode: SCNNode) {
        cameraNode.position = SCNVector3()
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, 0, -100000)
        cameraNode.rotation = SCNVector4()
        scale = 1
    }
    
    func resetCamera() {
        camera.orthographicScale = 20
        applyCameraNodeDefaultSettings(cameraNode: cameraNode)
    }
    
    func clear() {
        spheres.childNodes.forEach { $0.removeFromParentNode() }
        lineSegments.childNodes.forEach { $0.removeFromParentNode() }
        orbitalMotions.removeAll()
    }
    
    private func drawOrbitalMotion(motion: OrbitalMotion, color: UIColor, identifier: String) {
        let numberOfVertices: Int = 50
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial = {
            let mat = SCNMaterial()
            mat.diffuse.contents = color
            return mat
        }()
        motion.julianDate = julianDate
        if let planetNode = spheres.childNode(withName: identifier, recursively: false) {
            planetNode.position = transform(position: motion.position)
        } else {
            let planetNode = SCNNode(geometry: sphere)
            planetNode.name = identifier
            planetNode.position = transform(position: motion.position)
            spheres.addChildNode(planetNode)
        }

        func vertex(forIndex index: Int, totalIndex: Int) -> SCNVector3 {
            let offset = Float(index) / Float(totalIndex) * Float(M_PI * 2)
            let (position, _) = motion.stateVectors(fromTrueAnomaly: offset)
            return transform(position: position)
        }
        
        func addNode(totalIndex: Int, identifier: String) {
            let vertices = Array(0..<numberOfVertices).map { index in
                return vertex(forIndex: index, totalIndex: totalIndex)
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
            lineNode.name = identifier
            let justColor = SCNMaterial()
            justColor.diffuse.contents = color
            line.firstMaterial = justColor
            lineSegments.addChildNode(lineNode)
        }
        
        guard lineSegments.childNode(withName: identifier, recursively: false) == nil else {
            return
        }
        addNode(totalIndex: numberOfVertices, identifier: identifier)
    }
    
    private func transform(position: SCNVector3) -> SCNVector3 {
        return position / astronomicalUnitDist * 10
    }

}
