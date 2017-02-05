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

class ObserverScene: SCNScene, CameraControlling, FocusingSupport, SCNNodeRendererDelegate {
    
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
        let scene = SCNScene(named: "stars.scnassets/celestial_sphere.scn")!
        let milkyWayNode = scene.rootNode.childNode(withName: "milky_way", recursively: true)!
        milkyWayNode.transform = SCNMatrix4Identity
        milkyWayNode.removeFromParentNode()
        let sphere = milkyWayNode.geometry as! SCNSphere
        sphere.firstMaterial!.cullMode = .front
        sphere.radius = 12
        let mtx = SCNMatrix4MakeRotation(Float(-M_PI_2), 1, 0, 0)
        milkyWayNode.pivot = SCNMatrix4Scale(mtx, -1, 1, 1)
        milkyWayNode.opacity = 0.5
        rootNode.addChildNode(milkyWayNode)
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
//            let starNode = SCNNode()
            let starNode = SCNNode(geometry: SCNSphere(radius: radiusForMagnitude(star.physicalInfo.magnitude)))
            let coord = star.physicalInfo.coordinate.normalized() * 10
            starNode.position = SCNVector3(coord)
            starNode.geometry!.firstMaterial!.diffuse.contents = UIColor.white
            starNode.name = String(star.identity.id)
//            starNode.rendererDelegate = self
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
        cameraNode.transform = SCNMatrix4Identity
        (camera.xFov, camera.yFov) = (ObserverScene.defaultFov, ObserverScene.defaultFov)
        scale = 1
    }
    
    func focus(atNode node: SCNNode) {
        
    }
    
    private func radiusForMagnitude(_ mag: Double, blendOutStart: Double = 0, blendOutEnd: Double = 5) -> CGFloat {
        let maxSize: Double = 0.15
        let minSize: Double = 0.02
        let linearEasing = Easing(startValue: maxSize, endValue: minSize)
        let progress = mag / (blendOutEnd - blendOutStart)
        return CGFloat(linearEasing.value(at: progress))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - SCNNode Renderer Delegate
    func renderNode(_ node: SCNNode, renderer: SCNRenderer, arguments: [String : Any]) {
        print(node)
    }
}
