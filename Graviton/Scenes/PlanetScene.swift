//
//  PlanetScene.swift
//  Graviton
//
//  Created by Sihao Lu on 1/8/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits

class PlanetScene: SCNScene {
    func create() {
//        // create a new scene
//        let scene = SCNScene(named: "art.scnassets/earth.scn")!
//        // retrieve the ship node
//        let eNode = scene.rootNode.childNode(withName: "earth", recursively: true)!
//        eNode.removeFromParentNode()
//        let earthNode = CelestialNode(body: CelestialBody(knownBody: .earth), geometry: eNode.geometry)
//        scene.rootNode.addChildNode(earthNode)
//        
//        // create and add a camera to the scene
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        scene.rootNode.addChildNode(cameraNode)
//        let lookAt = SCNLookAtConstraint(target: earthNode)
//        lookAt.isGimbalLockEnabled = false
//        cameraNode.constraints = [lookAt]
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: geoSyncAltitude / earthEquatorialRadius + 1) + earthNode.position
//        
//        // create and add a light to the scene
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light!.type = .omni
//        lightNode.position = SCNVector3(x: 144598667960.65134, y: 38513399986.32562, z: 0) / earthEquatorialRadius
//        
//        scene.rootNode.addChildNode(lightNode)
//        
//        // animate the 3d object
//        let duration: CGFloat = 1200
//        earthNode.runAction(SCNAction.repeatForever(SCNAction.customAction(duration: TimeInterval(duration)) { (node, elapsedTime) in
//            let percentage = Float(elapsedTime / duration)
//            self.system.time = earthYear * percentage
//            lightNode.position = self.earth.heliocentricPosition.negated() / earthEquatorialRadius
//            cameraNode.position = SCNVector3(x: 0, y: 0, z: geoSyncAltitude / earthEquatorialRadius + 1) + node.position
//            print("\(elapsedTime / duration), \(self.earth.motion!.distance)")
//        }))
//        let rotationAxis = earthNode.rotationAxis
//        earthNode.runAction(SCNAction.repeatForever(SCNAction.rotate(by: CGFloat(M_PI * 2), around: rotationAxis, duration: Double(duration / 365.0))))
//        
    }
}
