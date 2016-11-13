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

class SolScene: SCNScene {
    var timeElapsed: Float = 0 {
        didSet {
            lineSegments.childNodes.forEach { $0.removeFromParentNode() }
            orbits.forEach { (orbit, color, identifier) in
                self.drawOrbit(orbit: orbit, color: color, identifier: identifier)
            }
        }
    }
    
    var orbits = [(Orbit, UIColor, String)]()
    var lineSegments = SCNNode()
    var spheres = SCNNode()
    
    override init() {
        super.init()
        let cameraNode = SCNNode()
        let sun = SCNNode(geometry: SCNSphere(radius: 0.9))
        sun.geometry!.firstMaterial = {
            let mat = SCNMaterial()
            mat.emission.contents = UIColor.white
            return mat
        }()
        sun.light = SCNLight()
        sun.light!.type = .omni
        rootNode.addChildNode(sun)
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 200
        rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 50)
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light?.intensity = 200
        rootNode.addChildNode(ambient)
        rootNode.addChildNode(lineSegments)
        rootNode.addChildNode(spheres)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addOrbit(orbit: Orbit, color: UIColor, identifier: String) {
        orbits.append((orbit, color, identifier))
        drawOrbit(orbit: orbit, color: color, identifier: identifier)
    }
    
    private func drawOrbit(orbit: Orbit, color: UIColor, identifier: String) {
        var motion = OrbitalMotion(centralBody: CelestialBody.sun, orbit: orbit)
        let numberOfVertices: Int = 200
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial = {
            let mat = SCNMaterial()
            mat.diffuse.contents = color
            return mat
        }()
        motion.setTime(timeElapsed)
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
