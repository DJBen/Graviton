//
//  SceneControlViewController.swift
//  Graviton
//
//  Created by Sihao Lu on 1/8/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

class SceneControlViewController: UIViewController, SCNSceneRendererDelegate {

    var cameraController: CameraControlling?
    
    lazy var pan: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(sender:)))
    
    lazy var doubleTap: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer(target: self, action: #selector(recenter(sender:)))
        gr.numberOfTapsRequired = 2
        return gr
    }()
    
    lazy var zoom: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(zoom(sender:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(zoom)
    }
    
    func recenter(sender: UIGestureRecognizer) {
        slideVelocity = CGPoint()
        referenceSlideVelocity = CGPoint()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        cameraController?.resetCamera()
        SCNTransaction.commit()
    }
    
    private var previousScale: Double?
    func zoom(sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            previousScale = cameraController?.scale
        case .changed:
            cameraController?.scale = previousScale! * Double(sender.scale)
        case .ended:
            cameraController?.scale = previousScale! * Double(sender.scale)
            previousScale = nil
        default:
            break
        }
    }
    
    private var slideVelocity: CGPoint = CGPoint()
    private var referenceSlideVelocity: CGPoint = CGPoint()
    private var slidingStopTimestamp: TimeInterval?
    
    func pan(sender: UIPanGestureRecognizer) {
        slideVelocity = sender.velocity(in: view).cap(to: viewSlideVelocityCap)
        referenceSlideVelocity = slideVelocity
        slidingStopTimestamp = nil
    }
    
    var viewSlideDivisor: CGFloat = 5000
    var viewSlideVelocityCap: CGFloat = 800
    var viewSlideInertiaDuration: TimeInterval = 1
    
    private func handleCameraSpin(atTime time: TimeInterval) {
        guard let cameraNode = cameraController?.cameraNode else {
            return
        }
        
        // spin the camera according the the user's swipes
        let oldRot: SCNQuaternion = cameraNode.rotation  //get the current rotation of the camera as a quaternion
        var rot: GLKQuaternion = GLKQuaternionMakeWithAngleAndAxis(oldRot.w, oldRot.x, oldRot.y, oldRot.z)  //make a GLKQuaternion from the SCNQuaternion
        
        // the next function calls take these parameters: rotationAngle, xVector, yVector, zVector
        // the angle is the size of the rotation (radians) and the vectors define the axis of rotation
        let rotX: GLKQuaternion = GLKQuaternionMakeWithAngleAndAxis(Float(-slideVelocity.x / viewSlideDivisor), 0, 1, 0) //For rotation when swiping with X we want to rotate *around* y axis, so if our vector is 0,1,0 that will be the y axis
        let rotY: GLKQuaternion = GLKQuaternionMakeWithAngleAndAxis(Float(-slideVelocity.y / viewSlideDivisor), 1, 0, 0) //For rotation by swiping with Y we want to rotate *around* the x axis.  By the same logic, we use 1,0,0
        let netRot: GLKQuaternion = GLKQuaternionMultiply(rotX, rotY) //To combine rotations, you multiply the quaternions.  Here we are combining the x and y rotations
        rot = GLKQuaternionMultiply(rot, netRot) //finally, we take the current rotation of the camera and rotate it by the new modified rotation.
        
        // then we have to separate the GLKQuaternion into components we can feed back into SceneKit
        let axis = GLKQuaternionAxis(rot)
        let angle = GLKQuaternionAngle(rot)
        
        //finally we replace the current rotation of the camera with the updated rotation
        cameraNode.rotation = SCNVector4Make(axis.x, axis.y, axis.z, angle)

        // dampen velocity
        if slidingStopTimestamp == nil {
            slidingStopTimestamp = time
        } else {
            let p = min((time - slidingStopTimestamp!) / viewSlideInertiaDuration, 1) - 1
            let factor: CGFloat = CGFloat(-p * p * p)
            slideVelocity = CGPoint(x: referenceSlideVelocity.x * factor, y: referenceSlideVelocity.y * factor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        handleCameraSpin(atTime: time)
    }
}

extension CGPoint {
    func cap(to p: CGFloat) -> CGPoint {
        return CGPoint(x: x > 0 ? min(x, p) : max(x, -p), y: y > 0 ? min(y, p) : max(y, -p))
    }
}
