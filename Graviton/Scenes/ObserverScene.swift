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
import GLKit

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
    
    private static let defaultFov: Double = 45
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
    
    var focusedNode: SCNNode?
    
    override init() {
        super.init()
        resetCamera()
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
        // camera points to north by default
        cameraNode.pivot = SCNMatrix4MakeRotation(Float(M_PI), 0, 1, 0)
        cameraNode.transform = SCNMatrix4Identity
        (camera.xFov, camera.yFov) = (ObserverScene.defaultFov, ObserverScene.defaultFov)
        scale = 1
    }
    
    func focus(atNode node: SCNNode) {
        
    }
    
    private func radiusForMagnitude(_ mag: Double, blendOutStart: Double = 0, blendOutEnd: Double = 5) -> CGFloat {
        let maxSize: CGFloat = 0.15
        let minSize: CGFloat = 0.02
        if mag < blendOutStart {
            return maxSize
        }
        if mag > blendOutEnd {
            return minSize
        }
        return maxSize - (maxSize - minSize) * CGFloat((mag - blendOutStart) / (blendOutEnd - blendOutStart))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
