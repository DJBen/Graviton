//
//  ObserverCameraController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import SpaceTime
import MathUtil

class ObserverCameraController: CameraController {
    private var stabilizer = AttitudeStabilizer()
    private var lastApplied: Quaternion = .identity

    override init() {
        super.init()
        configureStabilizer(stabilizeCamera: Settings.default[.stabilizeCamera])
        Settings.default.subscribe(setting: .stabilizeCamera, object: self) { self.configureStabilizer(stabilizeCamera: $1) }
    }

    private func configureStabilizer(stabilizeCamera: Bool) {
        stabilizer.sampleTimeWindow = stabilizeCamera ? 10 / 60 : 0
        stabilizer.angularSeparationThreshold = stabilizeCamera ? radians(degrees: 0.5) : 0
    }

    deinit {
        Settings.default.unsubscribe(object: self)
    }

    // I don't know why such algorithm is working. It is working nonetheless.
    override func handleCameraPan(atTime time: TimeInterval) {
        if MotionManager.default.isActive {
            return
        }
        let observerInfo = LocationAndTimeManager.default.observerInfo ?? LocationAndTime()
        let quat = Quaternion(rotationMatrix: observerInfo.localViewTransform)
        guard let cameraNode = cameraNode else { return }
        let rot = lastApplied.inverse * Quaternion(axisAngle: Vector4(cameraNode.rotation))
        let controlSpaceTransform = Quaternion(axisAngle: Vector4(1, 0, 0, -Double.pi / 2))
        lastApplied = quat * controlSpaceTransform
        var (pitch, yaw, _) = rot.toPitchYawRoll()
        // cap camera pitch near singularies
        if pitch > 0.97 * Double.pi / 2 && pitch < Double.pi / 2 {
            pitch = 0.97 * Double.pi / 2
        } else if pitch < -0.97 * Double.pi / 2 && pitch > -Double.pi {
            pitch = -0.97 * Double.pi / 2
        }
        let derolledRot = lastApplied * Quaternion.init(pitch: pitch, yaw: yaw, roll: 0)
        let movement = controlSpaceTransform * Quaternion(pitch: cameraYaw * cos(pitch), yaw: -cameraPitch, roll: 0)
        cameraNode.orientation = SCNQuaternion(derolledRot * movement)
        decelerateCamera(atTime: time)
    }

    override func handleCameraRotation(atTime time: TimeInterval) {
        // disable
    }

    // I don't know why such algorithm is working. It is working nonetheless.
    func deviceMotionDidUpdate(motion: CMDeviceMotion) {
        stabilizer.addDeviceMotion(motion)
        slideVelocity = CGPoint.zero
        let observerInfo = LocationAndTimeManager.default.observerInfo ?? LocationAndTime()
        let quat = Quaternion(rotationMatrix: observerInfo.localViewTransform)
        let transform = Quaternion(pitch: Double.pi / 2, yaw: 0, roll: 0) * Quaternion(axisAngle: Vector4(0, 1, 0, Double.pi / 2))
        let eulerSpace = transform.inverse * stabilizer.smoothedQuaternion * transform
        let final = Quaternion(pitch: 0, yaw: 0, roll: Double.pi / 2) * Quaternion(pitch: Double.pi / 2, yaw: 0, roll: 0) * eulerSpace
        cameraNode?.orientation = SCNQuaternion(quat * final)
    }

}
