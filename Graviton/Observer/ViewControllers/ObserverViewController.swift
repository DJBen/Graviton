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

var ephemerisSubscriptionIdentifier: SubscriptionUUID!

class ObserverViewController: SceneController, SnapshotSupport, SKSceneDelegate, MenuBackgroundProvider {

    private lazy var obsScene = ObserverScene()
    private var obsSubscriptionIdentifier: SubscriptionUUID!
    private var locationSubscriptionIdentifier: SubscriptionUUID!

    private var scnView: SCNView {
        return self.view as! SCNView
    }

    var currentSnapshot: UIImage {
        return scnView.snapshot()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentTransparentNavigationBar()
    }

    deinit {
        EphemerisMotionManager.default.unsubscribe(ephemerisSubscriptionIdentifier)
        ObserverEphemerisManager.default.unsubscribe(obsSubscriptionIdentifier)
        LocationManager.default.unsubscribe(locationSubscriptionIdentifier)
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

    override func zoom(sender: UIPinchGestureRecognizer) {
        super.zoom(sender: sender)
        configurePanSpeed()
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
        scnView.autoenablesDefaultLighting = false

        cameraModifier = obsScene
        cameraController.viewSlideVelocityCap = 500
        cameraController.cameraInversion = [.invertX, .invertY]
        cameraController.cameraNode = obsScene.cameraNode
        configurePanSpeed()

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapGR.require(toFail: doubleTap)
        view.addGestureRecognizer(tapGR)
    }

    func handleTap(sender: UITapGestureRecognizer) {
        // TODO: Implement star seeking
    }

    override func sceneDidRenderFirstTime(scene: SCNScene) {
        super.sceneDidRenderFirstTime(scene: scene)
        ephemerisSubscriptionIdentifier = EphemerisMotionManager.default.subscribe(mode: .interval(10), didLoad: obsScene.ephemerisDidLoad(ephemeris:), didUpdate: obsScene.ephemerisDidUpdate(ephemeris:))
        obsSubscriptionIdentifier = ObserverEphemerisManager.default.subscribe(didLoad: obsScene.observerInfoUpdate(observerInfo:))
        locationSubscriptionIdentifier = LocationManager.default.subscribe(didUpdate: obsScene.updateLocation(location:))
    }

    private func configurePanSpeed() {
        let factor = CGFloat(ObserverScene.defaultFov / obsScene.fov)
        cameraController.viewSlideDivisor = factor * 25000
    }

    // MARK: - Scene Renderer Delegate

    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        super.renderer(renderer, didRenderScene: scene, atTime: time)
        EphemerisMotionManager.default.request(at: JulianDate.now(), forSubscription: ephemerisSubscriptionIdentifier)
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
