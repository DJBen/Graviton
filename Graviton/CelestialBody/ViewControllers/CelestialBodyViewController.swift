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

    private var obsSubscriptionIdentifier: SubscriptionUUID!
    private var rtsSubscriptionIdentifier: SubscriptionUUID!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        obsSubscriptionIdentifier = CelestialBodyObserverInfoManager.default.subscribe(didLoad: cbScene.updateObserverInfo)
        rtsSubscriptionIdentifier = RiseTransitSetManager.default.subscribe(didLoad: cbScene.updateRiseTransitSetInfo)
    }

    private func setupViewElements() {
        scnView.delegate = self
        scnView.antialiasingMode = .multisampling4X
        scnView.scene = cbScene
        scnView.pointOfView = cbScene.cameraNode
        scnView.backgroundColor = UIColor.black
        scnView.isPlaying = true

        cameraModifier = cbScene
        cameraController.viewSlideDivisor = 8000
        cameraController.viewSlideVelocityCap = 800
        cameraController.viewSlideInertiaDuration = 1.5
    }

    deinit {
        CelestialBodyObserverInfoManager.default.unsubscribe(obsSubscriptionIdentifier)
        RiseTransitSetManager.default.unsubscribe(rtsSubscriptionIdentifier)
    }
}
