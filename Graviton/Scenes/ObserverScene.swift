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

class ObserverScene: SCNScene, CameraControlling {
    
    lazy var stars = DistantStar.magitudeLessThan(4)
    
    private lazy var camera: SCNCamera = {
        let c = SCNCamera()
        c.usesOrthographicProjection = false
        c.automaticallyAdjustsZRange = true
        c.xFov = 60
        c.yFov = 60
        return c
    }()
    
    lazy var cameraNode: SCNNode = {
        let cn = SCNNode()
        cn.position = SCNVector3Zero
        cn.pivot = SCNMatrix4Identity
        cn.camera = self.camera
        return cn
    }()
    
    var scale: Double = 1
    
    override init() {
        super.init()
        let light: SCNNode = {
            let node = SCNNode()
            node.light = {
                let light = SCNLight()
                light.type = .ambient
                return light
            }()
            return node
        }()
        rootNode.addChildNode(light)
        rootNode.addChildNode(cameraNode)
        for star in stars {
            let starNode = SCNNode(geometry: SCNSphere(radius: radiusForMagnitude(star.physicalInfo.magnitude)))
            let coord = star.physicalInfo.coordinate.normalized() * 10
            print(coord)
            starNode.position = SCNVector3(coord)
            starNode.geometry!.firstMaterial!.diffuse.contents = UIColor.white
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
    }
    
    func resetCamera() {
        cameraNode.position = SCNVector3Zero
        cameraNode.pivot = SCNMatrix4Identity
        scale = 1
    }
    
    private func radiusForMagnitude(_ mag: Double, blendOutStart: Double = 0, blendOutEnd: Double = 4) -> CGFloat {
        let defaultMag: CGFloat = 0.15
        if mag < blendOutStart {
            return defaultMag
        }
        if mag > blendOutEnd {
            return 0
        }
        return defaultMag * CGFloat(1 - (mag - blendOutStart) / (blendOutEnd - blendOutStart))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
