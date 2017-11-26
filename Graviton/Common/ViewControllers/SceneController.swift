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

    @available(*, deprecated, message: "use SCNCameraController")
    var legacyCameraController: CameraController?
    var cameraController: SCNCameraController?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadCameraController()
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(zoom)
        view.addGestureRecognizer(rotationGR)
    }

    @objc func recenter(sender: UIGestureRecognizer) {
        legacyCameraController?.slideVelocity = CGPoint()
        legacyCameraController?.referenceSlideVelocity = CGPoint()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraModifier?.resetCamera()
        SCNTransaction.commit()
    }

    func loadCameraController() {
        legacyCameraController = CameraController()
    }

    @objc func zoom(sender: UIPinchGestureRecognizer) {
        guard let legacyCameraController = legacyCameraController else {
            return
        }
        switch sender.state {
        case .began:
            legacyCameraController.previousScale = cameraModifier?.scale
            sender.scale = CGFloat((cameraModifier?.scale ?? 1) / (legacyCameraController.previousScale ?? 1))
        case .changed:
            cameraModifier?.scale = legacyCameraController.previousScale! * Double(sender.scale)
            sender.scale = CGFloat((cameraModifier?.scale ?? 1) / (legacyCameraController.previousScale ?? 1))
        case .ended:
            cameraModifier?.scale = legacyCameraController.previousScale! * Double(sender.scale)
            sender.scale = CGFloat((cameraModifier?.scale ?? 1) / (legacyCameraController.previousScale ?? 1))
            legacyCameraController.previousScale = nil
        default:
            break
        }
    }

    @objc func pan(sender: UIPanGestureRecognizer) {
        guard let legacyCameraController = legacyCameraController else {
            return
        }
        legacyCameraController.slideVelocity = sender.velocity(in: view).cap(to: legacyCameraController.viewSlideVelocityCap)
        legacyCameraController.referenceSlideVelocity = legacyCameraController.slideVelocity
        legacyCameraController.slidingStopTimestamp = nil
    }

    @objc func rotate(sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .began:
            legacyCameraController?.previousRotation = cameraModifier?.cameraNode.rotation
        case .ended:
            legacyCameraController?.previousRotation = nil
        default:
            break
        }
    }

    // MARK: - Scene Renderer Delegate

    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        legacyCameraController?.handleCameraPan(atTime: time)
        legacyCameraController?.rotation = rotationGR.rotation
        legacyCameraController?.handleCameraRotation(atTime: time)
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
