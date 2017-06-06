//
//  ObserverCameraController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import MathUtil

class ObserverCameraController: CameraController {
    override var cameraMovement: Quaternion {
        var yaw = Quaternion(axisAngle: Vector4(0, 0, 1, Double(-slideVelocity.x / viewSlideDivisor)))
        if cameraInversion.contains(.invertYaw) {
            yaw = yaw.inverse
        }
        var pitch = Quaternion(axisAngle: Vector4(0, 1, 0, Double(slideVelocity.y / viewSlideDivisor)))
        if cameraInversion.contains(.invertPitch) {
            pitch = pitch.inverse
        }
        return pitch * yaw
    }

    override func handleCameraPan(atTime time: TimeInterval) {
        guard let cameraNode = cameraNode else { return }
        let rot = Quaternion(axisAngle: Vector4(cameraNode.rotation))
        
        let finalRot = rot * cameraMovement
        var axisAngle = finalRot.toAxisAngle()
        axisAngle.x = -axisAngle.y
//        cameraNode.orientation = SCNQuaternion(Quaternion.init(axisAngle: axisAngle))
        cameraNode.orientation = SCNQuaternion(finalRot)
        fadeOutCameraMovement(atTime: time)
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
