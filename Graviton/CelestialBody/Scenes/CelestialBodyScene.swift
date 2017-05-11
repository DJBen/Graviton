//
//  CelestialBodyScene.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import MathUtil

class CelestialBodyScene: SCNScene, CameraControlling {
    static let defaultFov: Double = 30

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

    var scale: Double = 1

    func resetCamera() {
        cameraNode.position = SCNVector3()
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, 0, -5)
        cameraNode.rotation = SCNVector4()
    }

    override init() {
        super.init()
        rootNode.addChildNode(cameraNode)
        resetCamera()
        let node = CelestialBodyNode(naif: .moon(.luna))
        rootNode.addChildNode(node)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
