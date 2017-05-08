//
//  CelestialBodyViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

class CelestialBodyViewController: SceneController {
    private lazy var cbScene = CelestialBodyScene()
    private var scnView: SCNView {
        return self.view as! SCNView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
    }

    private func setupViewElements() {
        scnView.delegate = self
        scnView.antialiasingMode = .multisampling2X
        scnView.scene = cbScene
        scnView.pointOfView = cbScene.cameraNode
        scnView.backgroundColor = UIColor.black
        scnView.isPlaying = true

        cameraController = cbScene
        viewSlideDivisor = 8000
        viewSlideVelocityCap = 800
        viewSlideInertiaDuration = 1.5
    }
}
