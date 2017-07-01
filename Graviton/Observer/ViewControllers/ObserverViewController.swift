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

    static let dataFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd hh:mm a 'UTC'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        return formatter
    }()

    private lazy var overlayScene: ObserverOverlayScene = ObserverOverlayScene(size: self.view.bounds.size)
    private lazy var observerScene = ObserverScene()
    private var observerSubscriptionIdentifier: SubscriptionUUID!
    private var locationAndTimeSubscriptionIdentifier: SubscriptionUUID!
    private var motionSubscriptionIdentifier: SubscriptionUUID!
    private var isTimeWarpActive: Bool = false
    private var timeWarpSpeed: Double?

    private lazy var titleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        button.titleLabel?.textColor = UIColor.white
        button.autoresizingMask = .flexibleWidth
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = TextStyle.Font.monoLabelFont(size: 16)
        button.addTarget(self, action: #selector(toggleTimeWarp(sender:)), for: .touchUpInside)
        return button
    }()

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
        MotionManager.default.unsubscribe(motionSubscriptionIdentifier)
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
        cameraController.cameraNode = observerScene.cameraNode
        cameraController.cameraInversion = .invertAll
        configurePanSpeed()
    }

    override func menuButtonTapped(sender: UIButton) {
        stopTimeWarp(withAnimationDuration: 0)
        scnView.pause(nil)
        let menuController = ObserverMenuController(style: .plain)
        menuController.menu = Menu.main
        navigationController?.pushViewController(menuController, animated: true)
    }

    private func setupViewElements() {
        navigationController?.navigationBar.tintColor = Constants.Menu.tintColor
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_icon_gyro"), style: .plain, target: self, action: #selector(gyroButtonTapped(sender:)))
        navigationItem.leftBarButtonItem = barButtonItem
        navigationItem.titleView = titleButton

        scnView.delegate = self
        scnView.antialiasingMode = .multisampling2X
        scnView.scene = observerScene
        scnView.pointOfView = observerScene.cameraNode
        scnView.overlaySKScene = overlayScene
        scnView.backgroundColor = UIColor.black
        scnView.isPlaying = true
        scnView.autoenablesDefaultLighting = false

        cameraModifier = observerScene
        view.removeGestureRecognizer(doubleTap)
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        view.addGestureRecognizer(tapGR)

        let displaylink = CADisplayLink(target: self, selector: #selector(updateTimestampLabel))
        displaylink.add(to: .current, forMode: .defaultRunLoopMode)
    }

    func updateTimestampLabel() {
        let requestTimestamp = Timekeeper.default.content ?? JulianDate.now
        titleButton.setTitle(ObserverViewController.dataFormatter.string(from: requestTimestamp.date), for: .normal)
    }

    override func pan(sender: UIPanGestureRecognizer) {
        // if there's any pan event, cancel motion updates
        MotionManager.default.stopMotionUpdate()
        let location = sender.location(in: self.view)
        if isTimeWarpActive && CGRect(x: view.bounds.width - 44, y: 0, width: 44, height: view.bounds.height).contains(location) {
            let percentage = Double((view.bounds.height / 2 - sender.location(in: self.view).y) / (view.bounds.height / 2))
            let warpSpeed = percentage >= 0 ? exp(percentage * 16) : -exp(-percentage * 16)
            timeWarpSpeed = warpSpeed
        } else {
            super.pan(sender: sender)
        }
        if sender.state == .ended {
            timeWarpSpeed = nil
        }
    }

    func gyroButtonTapped(sender: UIBarButtonItem) {
        MotionManager.default.toggleMotionUpdate()
    }

    func toggleTimeWarp(sender: UIBarButtonItem) {
        guard Settings.default[.enableTimeWarp] else { return }
        isTimeWarpActive = !isTimeWarpActive
        print("Time warp toggled \(isTimeWarpActive)")
        if isTimeWarpActive {
            overlayScene.show(withDuration: 0.25)
        } else {
            stopTimeWarp(withAnimationDuration: 0.25)
        }
    }

    private func stopTimeWarp(withAnimationDuration animationDuration: Double) {
        Timekeeper.default.reset()
        ObserverInfoManager.default.julianDate = nil
        overlayScene.hide(withDuration: animationDuration)
    }

    func handleTap(sender: UITapGestureRecognizer) {
        let point = sender.location(in: view)
        let vec = SCNVector3(point.x, point.y, 0.5)
        let unitVec = Vector3(scnView.unprojectPoint(vec)).normalized()
        if let star = Star.closest(to: unitVec, maximumMagnitude: Constants.Observer.maximumDisplayMagnitude, maximumAngularDistance: radians(degrees: 15)) {
            let node = observerScene.rootNode.childNode(withName: String(star.identity.id), recursively: true)!
            observerScene.focus(atNode: node)
            overlayScene.displayStar(star)
        } else {
            overlayScene.hideStarDisplay()
        }
    }

    override func sceneDidRenderFirstTime(scene: SCNScene) {
        super.sceneDidRenderFirstTime(scene: scene)
        ephemerisSubscriptionIdentifier = EphemerisMotionManager.default.subscribe(mode: .interval(10), didLoad: observerScene.ephemerisDidLoad(ephemeris:), didUpdate: observerScene.ephemerisDidUpdate(ephemeris:))
        observerSubscriptionIdentifier = ObserverEphemerisManager.default.subscribe(didLoad: observerScene.observerInfoUpdate(observerInfo:))
        locationAndTimeSubscriptionIdentifier = ObserverInfoManager.default.subscribe(didUpdate: observerScene.updateLocationAndTime(observerInfo:))
        observerScene.motionSubscriptionId = ephemerisSubscriptionIdentifier
        motionSubscriptionIdentifier = MotionManager.default.subscribe(didUpdate: observerCameraController.deviceMotionDidUpdate(motion:))
    }

    private func configurePanSpeed() {
        let factor = CGFloat(ObserverScene.defaultFov / observerScene.fov)
        cameraController.viewSlideDivisor = factor * 25000
    }

    // MARK: - Scene renderer delegate

    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        super.renderer(renderer, didRenderScene: scene, atTime: time)
        if let warpSpeed = timeWarpSpeed {
            Timekeeper.default.warp(by: warpSpeed)
        }
        let requestTimestamp = Timekeeper.default.content ?? JulianDate.now
        EphemerisMotionManager.default.request(at: requestTimestamp, forSubscription: ephemerisSubscriptionIdentifier)
        ObserverInfoManager.default.julianDate = requestTimestamp
        configurePanSpeed()
        observerScene.rendererUpdate()
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
