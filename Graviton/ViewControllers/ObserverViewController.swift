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

class ObserverViewController: SceneController, UINavigationControllerDelegate, SnapshotSupport, SKSceneDelegate {
    
    private lazy var obsScene = ObserverScene()
    private var manager: EphemerisManager?
    private var scnView: SCNView {
        return self.view as! SCNView
    }
    private lazy var overlay: ObserverOverlayScene = {
        return ObserverOverlayScene(size: self.scnView.frame.size)
    }()
    
    var currentSnapshot: UIImage {
        return scnView.snapshot()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewElements()
        Horizons.shared.fetchEphemeris(mode: .preferLocal, update: { (ephemeris) in
            self.manager = EphemerisManager(mode: .interval(60), ephemeris: ephemeris)
            self.obsScene.ephemeris = ephemeris
        })
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
    
    func menuButtonTapped() {
        scnView.pause(nil)
        let menuController = ObserverMenuController(style: .plain)
        menuController.backgroundImage = scnView.snapshot()
        menuController.menu = Menu.main
        navigationController?.pushViewController(menuController, animated: true)
    }
    
    private func setupViewElements() {
        navigationController?.delegate = self
        let barButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_icon_menu"), style: .plain, target: self, action: #selector(menuButtonTapped))
        navigationItem.rightBarButtonItem = barButtonItem
        navigationController?.navigationBar.tintColor = Constants.Menu.tintColor
        scnView.delegate = self
        scnView.antialiasingMode = .multisampling2X
        scnView.isJitteringEnabled = true
        scnView.scene = obsScene
        scnView.pointOfView = obsScene.cameraNode
        cameraController = obsScene
        scnView.isPlaying = true
        scnView.overlaySKScene = overlay
        overlay.delegate = self
        scnView.backgroundColor = UIColor.black
        viewSlideVelocityCap = 500
        cameraInversion = [.invertX, .invertY]
    }
    
    private func starsInFrustrum() -> [(Star, CGPoint)] {
        let visibleNodes = obsScene.rootNode.childNodes { (child, _) -> Bool in
            if child.name == nil { return false }
            let projected = self.scnView.projectPoint(child.position)
            return self.scnView.frame.contains(CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y)))
        }
        return visibleNodes.flatMap { (node) -> (Star, CGPoint)? in
            if let name = node.name, let numId = Int(name), let star = Star.id(numId) {
                let coord = self.scnView.project3dTo2d(node.position).point
                return (star, coord)
            }
            return nil
        }
    }
    
    // MARK: - Scene Renderer Delegate
    
    override func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        super.renderer(renderer, didRenderScene: scene, atTime: time)
        guard let (eph, changed) = manager?.requestedEphemeris(at: JulianDate.now()) else { return }
        if changed {
            obsScene.updateEphemeris(eph)
        }
    }
    
    func update(_ currentTime: TimeInterval, for scene: SKScene) {
        func annotate(body: CelestialBody?) {
            guard let body = body else { return }
            let id = String(body.naifId)
            guard let node = self.obsScene.rootNode.childNode(withName: id, recursively: false) else { return }
            let pv = self.scnView.project3dTo2d(node.presentation.position)
            self.overlay.annotate(id, annotation: body.name, position: pv.point, class: .planets, isVisible: pv.visible)
        }
        obsScene.ephemeris?.forEach { (body) in
            guard case let .majorBody(mb) = body.naif else { return }
            if mb == .earth { return }
            annotate(body: body)
        }
        if let sun = self.obsScene.rootNode.childNode(withName: String(Sun.sol.naifId), recursively: false) {
            let pv = self.scnView.project3dTo2d(sun.presentation.position)
            self.overlay.annotate(String(Sun.sol.naifId), annotation: Sun.sol.name, position: pv.point, class: .sun, isVisible: pv.visible)
        }
    }
    
    // MARK: - Navigation Controller Delegate
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == self {
            obsScene.updateAccordingToSettings()
            scnView.play(nil)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let pushTransition = PushOverlayTransition(from: fromVC, to: toVC, operation: operation)
        return pushTransition
    }
}
