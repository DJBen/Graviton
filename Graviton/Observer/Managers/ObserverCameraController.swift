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

    override func handleCameraPan(atTime time: TimeInterval) {
        if MotionManager.default.isActive {
            return
        }
        let observerInfo = ObserverInfoManager.default.observerInfo ?? LocationAndTime()
        let quat = Quaternion(rotationMatrix: observerInfo.localViewTransform)
        guard let cameraNode = cameraNode else { return }
        let rot = lastApplied.inverse * Quaternion(axisAngle: Vector4(cameraNode.rotation))
        lastApplied = quat
        var eu = EulerAngle(quaternion: rot)
        // because of NED, invert roll by 180°.
        eu.roll = Double.pi
        // cap camera pitch near singularies
        if eu.pitch > 0.95 * Double.pi / 2 && eu.pitch < Double.pi / 2 {
            eu.pitch = 0.95 * Double.pi / 2
        } else if eu.pitch < Double.pi * 2 - 0.95 * Double.pi / 2 && eu.pitch > Double.pi * 3 / 2 {
            eu.pitch = Double.pi * 2 - 0.95 * Double.pi / 2
        }
        let derolledRot = lastApplied * Quaternion(eulerAngle: eu)
        let movement = Quaternion(eulerAngle: EulerAngle(yaw: cameraYaw * cos(eu.pitch), pitch: cameraPitch, roll: 0))
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
        let observerInfo = ObserverInfoManager.default.observerInfo ?? LocationAndTime()
        let quat = Quaternion(rotationMatrix: observerInfo.localViewTransform)
        // device space to NED
        let transform = Quaternion(axisAngle: Vector4(1, 0, 0, Double.pi)) * Quaternion(axisAngle: Vector4(0, 0, 1, Double.pi / 2)) * stabilizer.smoothedQuaternion
        let (pitch, yaw, roll) = transform.toPitchYawRoll()
        let pitchYaw = Quaternion(pitch: pitch - Double.pi / 2, yaw: -yaw, roll: Double.pi / 2)
        let rollTransform = Quaternion(pitch: 0, yaw: 0, roll: roll + Double.pi / 2)
        cameraNode?.orientation = SCNQuaternion(quat * rollTransform * pitchYaw)
    }
}
