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

class ObserverViewController: SceneController, SnapshotSupport, MenuBackgroundProvider {

    private lazy var obsScene = ObserverScene()
    private var observerSubscriptionIdentifier: SubscriptionUUID!
    private var locationAndTimeSubscriptionIdentifier: SubscriptionUUID!
    private var motionSubscriptionIdentifier: SubscriptionUUID!

    private var scnView: SCNView {
        return self.view as! SCNView
    }

    var currentSnapshot: UIImage {
        return scnView.snapshot()
    }

    var observerCameraController: ObserverCameraController {
        return cameraController as! ObserverCameraController
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
        ObserverEphemerisManager.default.unsubscribe(observerSubscriptionIdentifier)
        ObserverInfoManager.default.unsubscribe(locationAndTimeSubscriptionIdentifier)
//        MotionManager.default.unsubscribe(motionSubscriptionIdentifier)
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

    override func loadCameraController() {
        cameraController = ObserverCameraController()
        cameraController.viewSlideVelocityCap = 500
        cameraController.cameraNode = obsScene.cameraNode
        cameraController.cameraInversion = .invertAll
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
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_icon_gyro"), style: .plain, target: self, action: #selector(gyroButtonTapped(sender:)))
        navigationItem.leftBarButtonItem = barButtonItem

        scnView.delegate = self
        scnView.antialiasingMode = .multisampling2X
        scnView.scene = obsScene
        scnView.pointOfView = obsScene.cameraNode
        scnView.backgroundColor = UIColor.black
        scnView.isPlaying = true
        scnView.autoenablesDefaultLighting = false

        cameraModifier = obsScene

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapGR.require(toFail: doubleTap)
        view.addGestureRecognizer(tapGR)
    }

    func gyroButtonTapped(sender: UIBarButtonItem) {
        MotionManager.default.toggleMotionUpdate()
    }

    override func pan(sender: UIPanGestureRecognizer) {
        super.pan(sender: sender)
        // if there's any pan event, cancel motion updates
        MotionManager.default.stopMotionUpdate()
    }

    func handleTap(sender: UITapGestureRecognizer) {
        // TODO: Implement star seeking
    }

    override func sceneDidRenderFirstTime(scene: SCNScene) {
        super.sceneDidRenderFirstTime(scene: scene)
        ephemerisSubscriptionIdentifier = EphemerisMotionManager.default.subscribe(mode: .interval(10), didLoad: obsScene.ephemerisDidLoad(ephemeris:), didUpdate: obsScene.ephemerisDidUpdate(ephemeris:))
        observerSubscriptionIdentifier = ObserverEphemerisManager.default.subscribe(didLoad: obsScene.observerInfoUpdate(observerInfo:))
        locationAndTimeSubscriptionIdentifier = ObserverInfoManager.default.subscribe(didUpdate: obsScene.updateLocationAndTime(observerInfo:))
        obsScene.motionSubscriptionId = ephemerisSubscriptionIdentifier
        motionSubscriptionIdentifier = MotionManager.default.subscribe(didUpdate: observerCameraController.deviceMotionDidUpdate(motion:))
    }

    private func configurePanSpeed() {
        let factor = CGFloat(ObserverScene.defaultFov / obsScene.fov)
        cameraController.viewSlideDivisor = factor * 25000
    }

    // MARK: - Scene renderer delegate

    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        super.renderer(renderer, didRenderScene: scene, atTime: time)
        EphemerisMotionManager.default.request(at: JulianDate.now, forSubscription: ephemerisSubscriptionIdentifier)
        configurePanSpeed()
    }

    // MARK: - Menu background provider

    func menuBackgroundImage(fromVC: UIViewController, toVC: UIViewController) -> UIImage? {
        return UIImageEffects.blurredMenuImage(scnView.snapshot())
    }
}

fileprivate extension UIImageEffects {
    static func blurredMenuImage(_ image: UIImage) -> UIImage {
        return imageByApplyingBlur(to: image, withRadius: 28, tintColor: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1).withAlphaComponent(0.1), saturationDeltaFactor: 1.8, maskImage: nil)
    }
}
