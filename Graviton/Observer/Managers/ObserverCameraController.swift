//
//  ObserverCameraController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import SpaceTime
import MathUtil

class ObserverCameraController: CameraController {
    var lastAppliedCameraTransform = Quaternion.identity

    override func handleCameraPan(atTime time: TimeInterval) {
        let observerInfo = ObserverInfoManager.default.observerInfo ?? LocationAndTime()
        var quat = Quaternion(rotationMatrix: observerInfo.localViewTransform)
        guard let cameraNode = cameraNode else { return }
        let rot = Quaternion(axisAngle: Vector4(cameraNode.rotation))
        var eu = EulerAngle(quaternion: rot)
        eu.roll = 0
        let derolledRot = Quaternion(eulerAngle: eu)
        let movement = Quaternion(eulerAngle: EulerAngle(yaw: cameraYaw * cos(eu.pitch), pitch: cameraPitch, roll: 0))
        cameraNode.orientation = SCNQuaternion(derolledRot * movement)
        decelerateCamera(atTime: time)
    }

    override func handleCameraRotation(atTime time: TimeInterval) {
        guard let cameraNode = cameraNode, let oldRot = previousRotation else { return }
        var rot: GLKQuaternion = GLKQuaternionMakeWithAngleAndAxis(oldRot.w, oldRot.x, oldRot.y, oldRot.z)
        var roll: GLKQuaternion = GLKQuaternionMakeWithAngleAndAxis(Float(rotation), 1, 0, 0)
        if cameraInversion.contains(.invertRoll) {
            roll = GLKQuaternionInvert(roll)
        }
        rot = GLKQuaternionMultiply(rot, roll)

        let axis = GLKQuaternionAxis(rot)
        let angle = GLKQuaternionAngle(rot)
        cameraNode.rotation = SCNVector4Make(axis.x, axis.y, axis.z, angle)
    }
}
