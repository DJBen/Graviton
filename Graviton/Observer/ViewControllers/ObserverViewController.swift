//
//  ObserverViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 1/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit
import Orbits
import StarryNight
import SpaceTime
import MathUtil
import CoreImage
import CoreMedia

class ObserverViewController: SceneController, SnapshotSupport, SKSceneDelegate, MenuBackgroundProvider {

    private lazy var obsScene = ObserverScene()
    private var scnView: SCNView {
        return self.view as! SCNView
    }

    var currentSnapshot: UIImage {
        return scnView.snapshot()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapGR.require(toFail: doubleTap)
        self.view.addGestureRecognizer(tapGR)
        setupViewElements()
        EphemerisManager.default.subscribe(obsScene, mode: .interval(10))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentTransparentNavigationBar()
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

    override func handleCameraPan(atTime time: TimeInterval) {
        super.handleCameraPan(atTime: time)
        let factor = CGFloat(ObserverScene.defaultFov / obsScene.fov)
        viewSlideDivisor = factor * 25000
    }

    override func menuButtonTapped(sender: UIButton) {
        scnView.pause(nil)
        let menuController = ObserverMenuController(style: .plain)
        menuController.menu = Menu.main
        navigationController?.pushViewController(menuController, animated: true)
    }

    private func setupViewElements() {
        navigationController?.navigationBar.tintColor = Constants.Menu.tintColor
        scnView.delegate = self
        scnView.antialiasingMode = .multisampling2X
        scnView.scene = obsScene
        scnView.pointOfView = obsScene.cameraNode
        scnView.backgroundColor = UIColor.black
        scnView.isPlaying = true

        cameraController = obsScene
        viewSlideVelocityCap = 500
        cameraInversion = [.invertX, .invertY]
    }

    func handleTap(sender: UITapGestureRecognizer) {
        // TODO: Implement star seeking
    }

    // MARK: - Scene Renderer Delegate

    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        super.renderer(renderer, didRenderScene: scene, atTime: time)
        EphemerisManager.default.requestEphemeris(at: JulianDate.now(), forObject: obsScene)
    }

    // MARK: - Menu Background Provider

    func menuBackgroundImage(fromVC: UIViewController, toVC: UIViewController) -> UIImage? {
        return UIImageEffects.blurredMenuImage(scnView.snapshot())
    }
}

fileprivate extension UIImageEffects {
    static func blurredMenuImage(_ image: UIImage) -> UIImage {
        return imageByApplyingBlur(to: image, withRadius: 28, tintColor: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1).withAlphaComponent(0.1), saturationDeltaFactor: 1.8, maskImage: nil)
    }
}
