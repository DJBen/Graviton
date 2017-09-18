//
//  ObserverViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 1/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//
//  我们活在浩瀚的宇宙里
//  漫天飘洒的宇宙尘埃和星河光尘
//  我们是比这些还要渺小的存在

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

class ObserverViewController: SceneController, MenuBackgroundProvider {

    private lazy var overlayScene: ObserverOverlayScene = ObserverOverlayScene(size: self.view.bounds.size)
    private lazy var observerScene = ObserverScene()
    private var observerSubscriptionIdentifier: SubscriptionUUID!
    private var locationSubscriptionIdentifier: SubscriptionUUID!
    private var motionSubscriptionIdentifier: SubscriptionUUID!
    private var timeWarpSpeed: Double?

    private lazy var titleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = TextStyle.Font.monoLabelFont(size: 16)
        button.addTarget(self, action: #selector(toggleTimeWarp(sender:)), for: .touchUpInside)
        return button
    }()

    private lazy var titleBlurView: UIVisualEffectView = {
        var blurEffectView = UIVisualEffectView()
        blurEffectView.frame = CGRect(x: 0, y: 0, width: 200, height: self.navigationController!.navigationBar.frame.height - 16)
        blurEffectView.clipsToBounds = true
        blurEffectView.layer.cornerRadius = (self.navigationController!.navigationBar.frame.height - 16) / 2
        blurEffectView.layer.borderWidth = 1
        blurEffectView.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        blurEffectView.contentView.frame = blurEffectView.bounds
        blurEffectView.contentView.addSubview(self.titleButton)
        self.titleButton.center = blurEffectView.center
        return blurEffectView
    }()

    private var scnView: SCNView {
        return self.view as! SCNView
    }

    var target: BodyInfoTarget?

    var observerCameraController: ObserverCameraController {
        return cameraController as! ObserverCameraController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        ephemerisSubscriptionIdentifier = EphemerisManager.default.subscribe(mode: .interval(10), didLoad: observerScene.ephemerisDidLoad(ephemeris:), didUpdate: self.ephemerisDidUpdate(ephemeris:))
        observerSubscriptionIdentifier = CelestialBodyObserverInfoManager.default.subscribe(didLoad: observerScene.observerInfoUpdate(observerInfo:))
        locationSubscriptionIdentifier = LocationManager.default.subscribe(didUpdate: observerScene.updateLocation(location:))
        motionSubscriptionIdentifier = MotionManager.default.subscribe(didUpdate: observerCameraController.deviceMotionDidUpdate(motion:))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentTransparentNavigationBar()
        updateTimeLabel()
        updateAntialiasingMode(Settings.default[.antialiasingMode])
        Settings.default.subscribe(setting: .antialiasingMode, object: self) { (_, newKey) in
            self.updateAntialiasingMode(newKey)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopTimeWarp(withAnimationDuration: 0)
        observerScene.removeFocus()
        overlayScene.hideStarDisplay(withDuration: 0)
        target = nil
        Timekeeper.default.isWarpActive = false
        super.viewWillDisappear(animated)
    }

    deinit {
        EphemerisManager.default.unsubscribe(ephemerisSubscriptionIdentifier)
        CelestialBodyObserverInfoManager.default.unsubscribe(observerSubscriptionIdentifier)
        MotionManager.default.unsubscribe(motionSubscriptionIdentifier)
        Settings.default.unsubscribe(object: self)
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

    private func setupViewElements() {
        navigationController?.navigationBar.tintColor = Constants.Menu.tintColor
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_icon_gyro"), style: .plain, target: self, action: #selector(gyroButtonTapped(sender:)))
        navigationItem.leftBarButtonItem = barButtonItem
        navigationItem.titleView = titleBlurView

        scnView.delegate = self
        scnView.antialiasingMode = .none
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

    // MARK: - Button handling

    override func menuButtonTapped(sender: UIButton) {
        let menuController = ObserverMenuController()
        menuController.menu = Menu.main
        navigationController?.pushViewController(menuController, animated: true)
    }

    @objc func gyroButtonTapped(sender: UIBarButtonItem) {
        MotionManager.default.toggleMotionUpdate()
    }

    // MARK: - Gesture handling

    override func pan(sender: UIPanGestureRecognizer) {
        // if there's any pan event, cancel motion updates
        MotionManager.default.stopMotionUpdate()
        if sender.state == .ended {
            timeWarpSpeed = nil
            return
        }
        let location = sender.location(in: self.view)
        if Timekeeper.default.isWarpActive && CGRect(x: view.bounds.width - 44, y: 0, width: 44, height: view.bounds.height).contains(location) {
            let percentage = Double((view.bounds.height / 2 - sender.location(in: self.view).y) / (view.bounds.height / 2))
            let warpSpeed = percentage >= 0 ? exp(percentage * 16) : -exp(-percentage * 16)
            timeWarpSpeed = warpSpeed
        } else {
            super.pan(sender: sender)
        }
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        let point = sender.location(in: view)
        if point.y > view.frame.height - 40 - tabBarController!.tabBar.frame.height && overlayScene.isShowingStarLabel {
            performSegue(withIdentifier: "showBodyInfo", sender: self)
            return
        }
        let vec = SCNVector3(point.x, point.y, 0.5)
        let unitVec = Vector3(scnView.unprojectPoint(vec)).normalized()
        let ephemeris = EphemerisManager.default.content(for: ephemerisSubscriptionIdentifier)!
        if let closeBody = ephemeris.closestBody(toUnitPosition: unitVec, from: ephemeris[.majorBody(.earth)]!, maximumAngularDistance: radians(degrees: 3)) {
            observerScene.focus(atCelestialBody: closeBody)
            overlayScene.showCelestialBodyDisplay(closeBody)
            target = .nearbyBody(closeBody)
        } else if let star = Star.closest(to: unitVec, maximumMagnitude: Constants.Observer.maximumDisplayMagnitude, maximumAngularDistance: radians(degrees: 3)) {
            observerScene.focus(atStar: star)
            overlayScene.showStarDisplay(star)
            target = .star(star)
        } else {
            observerScene.removeFocus()
            overlayScene.hideStarDisplay()
            target = nil
        }
    }

    @objc func toggleTimeWarp(sender: UIBarButtonItem) {
        guard Settings.default[.enableTimeWarp] else { return }
        Timekeeper.default.isWarpActive = !Timekeeper.default.isWarpActive
        logger.verbose("Time warp toggled \(Timekeeper.default.isWarpActive)")
        updateTimeLabel()
    }

    // MARK: - Updates

    private func updateTimeLabel() {
        if Timekeeper.default.isWarpActive {
            LocationManager.default.unsubscribe(locationSubscriptionIdentifier)
            overlayScene.show(withDuration: 0.25)
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [], animations: {
                self.titleBlurView.effect = blurEffect
                self.titleButton.setTitleColor(UIColor.black, for: .normal)
            })
        } else {
            locationSubscriptionIdentifier = LocationManager.default.subscribe(didUpdate: observerScene.updateLocation(location:))
            stopTimeWarp(withAnimationDuration: 0.25)
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [], animations: {
                self.titleBlurView.effect = nil
                self.titleButton.setTitleColor(UIColor.white, for: .normal)
            })
        }
    }

    private func stopTimeWarp(withAnimationDuration animationDuration: Double) {
        Timekeeper.default.reset()
        LocationAndTimeManager.default.julianDate = nil
        overlayScene.hide(withDuration: animationDuration)
    }

    private func configurePanSpeed() {
        let factor = CGFloat(ObserverScene.defaultFov / observerScene.fov)
        cameraController.viewSlideDivisor = factor * 25000
    }

    @objc func updateTimestampLabel() {
        let requestTimestamp = Timekeeper.default.content ?? JulianDate.now
        titleButton.setTitle(Formatters.dateFormatter.string(from: requestTimestamp.date), for: .normal)
    }

    func ephemerisDidUpdate(ephemeris: Ephemeris) {
        assertMainThread()
        if let observerInfo = LocationAndTimeManager.default.observerInfo {
            self.observerCameraController.orientCameraNode(observerInfo: observerInfo)
        }
        observerScene.updateStellarContent()
    }

    private func updateAntialiasingMode(_ key: String) {
        scnView.antialiasingMode = SCNAntialiasingMode(rawValue: UInt(["none", "multisampling2X", "multisampling4X"].index(of: key)!))!
    }

    // MARK: - Perform segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBodyInfo", let dest = segue.destination as? ObserverDetailViewController {
            dest.target = target
            dest.ephemerisId = ephemerisSubscriptionIdentifier
        }
    }

    @IBAction func unwindFromBodyInfo(for segue: UIStoryboardSegue) {
    }

    // MARK: - Scene renderer delegate

    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        Timekeeper.default.warp(by: timeWarpSpeed)
        if Timekeeper.default.isWarpActive && Timekeeper.default.isWarping == false {
            super.renderer(renderer, didRenderScene: scene, atTime: time)
            return
        }
        if Timekeeper.default.isWarpActive {
            cameraController.slideVelocity = CGPoint.zero
        } else {
            super.renderer(renderer, didRenderScene: scene, atTime: time)
        }
        let requestTimestamp = Timekeeper.default.content ?? JulianDate.now
        LocationAndTimeManager.default.julianDate = requestTimestamp
        EphemerisManager.default.request(at: requestTimestamp, forSubscription: ephemerisSubscriptionIdentifier)
        configurePanSpeed()
        observerScene.rendererUpdate()
    }

    // MARK: - Menu background provider

    private var snapshottedImage: UIImage?
    func menuBackgroundImage(fromVC: UIViewController, toVC: UIViewController) -> UIImage? {
        if fromVC is ObserverViewController && toVC is MenuController {
            snapshottedImage = UIImageEffects.blurredMenuImage(scnView.snapshot())
        }
        return snapshottedImage
    }
}

fileprivate extension UIImageEffects {
    static func blurredMenuImage(_ image: UIImage) -> UIImage {
        return imageByApplyingBlur(to: image, withRadius: 28, tintColor: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1).withAlphaComponent(0.1), saturationDeltaFactor: 1.8, maskImage: nil)
    }
}
