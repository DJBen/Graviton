//
//  SceneController.swift
//  Graviton
//
//  Created by Sihao Lu on 1/8/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import MathUtil

class SceneController: UIViewController, SCNSceneRendererDelegate {

    var cameraModifier: CameraResponsive?

    lazy var pan: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(sender:)))

    lazy var doubleTap: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer(target: self, action: #selector(recenter(sender:)))
        gr.numberOfTapsRequired = 2
        return gr
    }()

    lazy var zoom: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(zoom(sender:)))

    lazy var rotationGR: UIRotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate(sender:)))

    let transitionController = NavigationTransitionController()

    var cameraController: CameraController!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadCameraController()
        navigationController?.delegate = transitionController
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(zoom)
        view.addGestureRecognizer(rotationGR)
    }

    @objc func recenter(sender: UIGestureRecognizer) {
        cameraController.slideVelocity = CGPoint()
        cameraController.referenceSlideVelocity = CGPoint()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraModifier?.resetCamera()
        SCNTransaction.commit()
    }

    func loadCameraController() {
        cameraController = CameraController()
    }

    @objc func zoom(sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            cameraController.previousScale = cameraModifier?.scale
            sender.scale = CGFloat((cameraModifier?.scale ?? 1) / (cameraController.previousScale ?? 1))
        case .changed:
            cameraModifier?.scale = cameraController.previousScale! * Double(sender.scale)
            sender.scale = CGFloat((cameraModifier?.scale ?? 1) / (cameraController.previousScale ?? 1))
        case .ended:
            cameraModifier?.scale = cameraController.previousScale! * Double(sender.scale)
            sender.scale = CGFloat((cameraModifier?.scale ?? 1) / (cameraController.previousScale ?? 1))
            cameraController.previousScale = nil
        default:
            break
        }
    }

    @objc func pan(sender: UIPanGestureRecognizer) {
        cameraController.slideVelocity = sender.velocity(in: view).cap(to: cameraController.viewSlideVelocityCap)
        cameraController.referenceSlideVelocity = cameraController.slideVelocity
        cameraController.slidingStopTimestamp = nil
    }

    @objc func rotate(sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .began:
            cameraController.previousRotation = cameraModifier?.cameraNode.rotation
        case .ended:
            cameraController.previousRotation = nil
        default:
            break
        }
    }

    // MARK: - Scene Renderer Delegate

    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        cameraController.handleCameraPan(atTime: time)
        cameraController.rotation = rotationGR.rotation
        cameraController.handleCameraRotation(atTime: time)
    }
}

extension CGPoint {
    /// Cap the value not to exceed an absolute magnitude
    ///
    /// - Parameter percentage: The value cap.
    /// - Returns: The capped value.
    func cap(to percentage: CGFloat) -> CGPoint {
        return CGPoint(x: x > 0 ? min(x, percentage) : max(x, -percentage), y: y > 0 ? min(y, percentage) : max(y, -percentage))
    }
}
