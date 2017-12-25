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

class ObserverViewController: SceneController {

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

    lazy var titleOverlayView: ObserverTitleOverlayView = {
        let overlay = ObserverTitleOverlayView(frame: CGRect.zero)
        overlay.delegate = self
        return overlay
    }()

    private var scnView: SCNView {
        return self.view as! SCNView
    }

    var target: ObserveTarget? {
        didSet {
            if let target = self.target {
                showTitleOverlay(target: target)
                focusAtTarget()
            } else {
                observerScene.removeFocus()
                hideTitleOverlay()
            }
        }
    }

    var observerCameraController: ObserverCameraController {
        return legacyCameraController as! ObserverCameraController
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
        updateTimeLabel()
        updateAntialiasingMode(Settings.default[.antialiasingMode])
        Settings.default.subscribe(setting: .antialiasingMode, object: self) { (_, newKey) in
            self.updateAntialiasingMode(newKey)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopTimeWarp(withAnimationDuration: 0)
        observerScene.removeFocus()
        hideTitleOverlay()
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
        return Device.isiPhoneX == false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func loadCameraController() {
        if Settings.default[.useCameraControllerV2] {
            cameraController = SCNCameraController()
            cameraController?.interactionMode = .orbitAngleMapping
            cameraController?.inertiaEnabled = true
            cameraController?.pointOfView = observerScene.cameraNode
        } else {
            legacyCameraController = ObserverCameraController()
            legacyCameraController?.viewSlideVelocityCap = 500
            legacyCameraController?.cameraNode = observerScene.cameraNode
            legacyCameraController?.cameraInversion = .invertAll
            configurePanSpeed()
        }
    }

    private func setupViewElements() {
        navigationController?.navigationBar.tintColor = Constants.Menu.tintColor
        let gyroItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_icon_gyro"), style: .plain, target: self, action: #selector(gyroButtonTapped(sender:)))
        navigationItem.leftBarButtonItem = gyroItem
        navigationItem.titleView = titleBlurView
        let settingItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_icon_settings"), style: .plain, target: self, action: #selector(menuButtonTapped(sender:)))
        let searchItem = UIBarButtonItem.init(barButtonSystemItem: .search, target: self, action: #selector(searchButtonTapped(sender:)))
        navigationItem.rightBarButtonItems = [settingItem, searchItem]

        titleOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleOverlayView)
        view.addConstraints(
            [
                titleOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                titleOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                titleOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )
        hideTitleOverlay()

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

    func center(atTarget target: ObserveTarget) {
        let ephemeris = EphemerisManager.default.content(for: ephemerisSubscriptionIdentifier)!
        let coordinate: Vector3
        switch target {
        case .nearbyBody(let body):
            coordinate = ephemeris.observedPosition(of: body as! CelestialBody, fromObserver: ephemeris[.majorBody(.earth)]!)
        case .star(let star):
            coordinate = star.physicalInfo.coordinate
        }
        self.observerScene.cameraNode.orientation = SCNQuaternion(Quaternion(alignVector: Vector3(1, 0, 0), with: coordinate))
    }

    private var titleOverlayHeightConstraint: NSLayoutConstraint?

    private func animateOverlayTitle(heightConstant: CGFloat) {
        if let prevConstraint = self.titleOverlayHeightConstraint {
            self.titleOverlayView.removeConstraint(prevConstraint)
        }
        self.titleOverlayHeightConstraint = self.titleOverlayView.heightAnchor.constraint(equalToConstant: heightConstant)
        self.titleOverlayView.addConstraint(self.titleOverlayHeightConstraint!)
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func showTitleOverlay(target: ObserveTarget) {
        self.titleOverlayView.title = String(describing: target)
        animateOverlayTitle(heightConstant: view.safeAreaInsets.bottom + 60)
    }

    private func hideTitleOverlay() {
        animateOverlayTitle(heightConstant: 0)
    }

    private func focusAtTarget() {
        guard let target = target else {
            return
        }
        switch target {
        case .nearbyBody(let closeBody):
            observerScene.focus(atCelestialBody: closeBody as! CelestialBody)
        case .star(let star):
            observerScene.focus(atStar: star)
        }
    }

    // MARK: - Button handling

    @objc func menuButtonTapped(sender: UIButton) {
        let menuController = ObserverMenuController(style: .plain)
        menuController.menu = Menu.main
        let navigationController = UINavigationController(rootViewController: menuController)
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.delegate = self
        self.tabBarController?.present(navigationController, animated: true, completion: nil)
    }

    @objc func gyroButtonTapped(sender: UIBarButtonItem) {
        MotionManager.default.toggleMotionUpdate()
    }

    @objc func searchButtonTapped(sender: UIBarButtonItem) {
        let targetSearchController = ObserveTargetSearchViewController(style: .plain)
        targetSearchController.delegate = self
        targetSearchController.ephemerisSubscriptionId = ephemerisSubscriptionIdentifier
        let navigationController = UINavigationController(rootViewController: targetSearchController)
        navigationController.modalPresentationStyle = .overCurrentContext
        self.tabBarController?.present(navigationController, animated: true, completion: nil)
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
        let vec = SCNVector3(point.x, point.y, 0.5)
        let unitVec = Vector3(scnView.unprojectPoint(vec)).normalized()
        let ephemeris = EphemerisManager.default.content(for: ephemerisSubscriptionIdentifier)!
        if let closeBody = ephemeris.closestBody(toUnitPosition: unitVec, from: ephemeris[.majorBody(.earth)]!, maximumAngularDistance: radians(degrees: 3)) {
            target = .nearbyBody(closeBody)
        } else if let star = Star.closest(to: unitVec, maximumMagnitude: Constants.Observer.maximumDisplayMagnitude, maximumAngularDistance: radians(degrees: 3)) {
            target = .star(star)
        } else {
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
        legacyCameraController?.viewSlideDivisor = factor * 25000
    }

    @objc func updateTimestampLabel() {
        let requestTimestamp = Timekeeper.default.content ?? JulianDate.now
        titleButton.setTitle(Formatters.dateFormatter.string(from: requestTimestamp.date), for: .normal)
    }

    func ephemerisDidUpdate(ephemeris: Ephemeris) {
        assertMainThread()
        if let observerInfo = LocationAndTimeManager.default.observerInfo {
            self.observerCameraController.orientCameraNode(observerInfo: observerInfo)
            observerScene.updateStellarContent(observerInfo: observerInfo)
        }
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
        // keep target selected
        if segue.identifier == "unwindFromBodyInfo", let source = segue.source as? ObserverDetailViewController {
            target = source.target
            focusAtTarget()
        }
    }

    // MARK: - Scene renderer delegate

    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        Timekeeper.default.warp(by: timeWarpSpeed)
        if Timekeeper.default.isWarpActive && Timekeeper.default.isWarping == false {
            super.renderer(renderer, didRenderScene: scene, atTime: time)
            return
        }
        if Timekeeper.default.isWarpActive {
            legacyCameraController?.slideVelocity = CGPoint.zero
        } else {
            super.renderer(renderer, didRenderScene: scene, atTime: time)
        }
        let requestTimestamp = Timekeeper.default.content ?? JulianDate.now
        LocationAndTimeManager.default.julianDate = requestTimestamp
        EphemerisManager.default.request(at: requestTimestamp, forSubscription: ephemerisSubscriptionIdentifier)
        configurePanSpeed()
        observerScene.rendererUpdate()
    }
}

// MARK: - Star search view controller delegate
extension ObserverViewController: ObserveTargetSearchViewControllerDelegate {
    func observeTargetViewController(_ viewController: ObserveTargetSearchViewController, didSelectTarget target: ObserveTarget) {
        dismiss(animated: true, completion: nil)
        self.target = target
        center(atTarget: self.target!)
    }
}

extension ObserverViewController: ObserverTitleOverlayViewDelegate {
    func titleOverlayTapped(view: ObserverTitleOverlayView) {
        performSegue(withIdentifier: "showBodyInfo", sender: self)
    }

    func titleOverlayFocusTapped(view: ObserverTitleOverlayView) {
        center(atTarget: self.target!)
    }
}

extension ObserverViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PushAsideTransition(presenting: operation == .push)
    }
}
