//
//  ObserverViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 1/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

class ObserverViewController: SceneControlViewController {
    
    lazy var obsScene = ObserverScene()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    private func setupViewElements() {
        let scnView = self.view as! SCNView
        scnView.delegate = self
        scnView.scene = obsScene
        scnView.isPlaying = true
        scnView.overlaySKScene = StarScene(size: scnView.frame.size)
        scnView.backgroundColor = UIColor.black
        scnView.allowsCameraControl = true
    }
}
