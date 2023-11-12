//
//  ObserverCameraController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreMotion
import MathUtil
import SceneKit
import SpaceTime
import UIKit

class ObserverCameraController: CameraController {
    private var stabilizer = AttitudeStabilizer()
    private var lastApplied: Quaternion = .identity
    
    // Startracker (st) variables
    // The quaternion solved for by the Startracker algorithm
    private var stQuat: Quaternion? = nil
    // Stores the rotation according to the IMU at the beginning of the Startracker algorithm running
    private var stDeviceMotionOffset: Quaternion? = nil
    private var saveDeviceMotionOffset: Bool = false

    override init() {
        super.init()
        configureStabilizer(stabilizeCamera: Settings.default[.stabilizeCamera])
        Settings.default.subscribe(setting: .stabilizeCamera, object: self) { self.configureStabilizer(stabilizeCamera: $1) }
    }

    private func configureStabilizer(stabilizeCamera: Bool) {
        stabilizer.sampleTimeWindow = stabilizeCamera ? 10 / 60 : 0
        stabilizer.angularSeparationThreshold = DegreeAngle(stabilizeCamera ? 0.5 : 0)
    }

    deinit {
        Settings.default.unsubscribe(object: self)
    }
    
    func setStartrackerOrientation(stQuat: Quaternion) {
        self.stQuat = stQuat
    }
    
    func requestSaveDeviceOrientationForStartracker() {
        self.saveDeviceMotionOffset = true
    }

    func orientCameraNode(observerInfo: ObserverLocationTime = ObserverLocationTime()) {
        let quat = Quaternion(rotationMatrix: observerInfo.localViewTransform)
        guard let cameraNode = cameraNode else { return }
        let rot = lastApplied.inverse * Quaternion(axisAngle: Vector4(cameraNode.rotation))
        let controlSpaceTransform = Quaternion(axisAngle: Vector4(1, 0, 0, -Double.pi / 2))
        lastApplied = quat * controlSpaceTransform
        var (pitch, yaw, _) = rot.toPitchYawRoll()
        // restrain camera pitch near singularities
        if pitch > 0.97 * Double.pi / 2 && pitch < Double.pi / 2 {
            pitch = 0.97 * Double.pi / 2
        } else if pitch < -0.97 * Double.pi / 2 && pitch > -Double.pi {
            pitch = -0.97 * Double.pi / 2
        }
        let derolledRot = lastApplied * Quaternion(pitch: pitch, yaw: yaw, roll: 0)
        let movement = controlSpaceTransform * Quaternion(pitch: cameraYaw * cos(pitch), yaw: -cameraPitch, roll: 0)
        cameraNode.orientation = SCNQuaternion(derolledRot * movement)
    }

    override func handleCameraPan(atTime time: TimeInterval) {
        if MotionManager.default.isActive {
            return
        }
        orientCameraNode(observerInfo: ObserverLocationTimeManager.default.observerInfo ?? ObserverLocationTime())
        decelerateCamera(atTime: time)
    }

    override func handleCameraRotation(atTime _: TimeInterval) {
        // disable
    }

    func deviceMotionDidUpdate(motion: CMDeviceMotion) {
        stabilizer.addDeviceMotion(motion)
        slideVelocity = CGPoint.zero
        let observerInfo = ObserverLocationTimeManager.default.observerInfo ?? ObserverLocationTime()
        let quat = Quaternion(rotationMatrix: observerInfo.localViewTransform)
        let transform = Quaternion(pitch: Double.pi / 2, yaw: 0, roll: 0) * Quaternion(axisAngle: Vector4(0, 1, 0, Double.pi / 2))
        let eulerSpace = transform.inverse * stabilizer.smoothedQuaternion * transform
        let final = Quaternion(pitch: 0, yaw: 0, roll: Double.pi / 2) * Quaternion(pitch: Double.pi / 2, yaw: 0, roll: 0) * eulerSpace
        var orientation = quat * final
        if self.saveDeviceMotionOffset {
            self.stDeviceMotionOffset = orientation
            self.saveDeviceMotionOffset = false
        }
        if self.stQuat != nil {
            // We need to provide T_R_M_\hat{j}, which is the Startracker-corrected orientation at time j (the current time)
            // We have:
            // - T_R_M_\hat{i} (aka self.stQuat). This is the Startracker-determined orientation at time i (when the photo was taken)
            // - T_R_M_i (aka self.stDeviceMotionOffset) This is the Motion-manager determined orientation at time i
            // - T_R_M_j (aka `orientation`). This is the Motion-managed determined orientation at time j
            // We need to solve: T_R_M_\hat{j} = T_R_M_\hat{i} * T_M_i_M_j
            // Note that T_M_i_M_j = T_M_i_R * T_R_M_j
            // We already know T_R_M_j. T_M_i_R = T_R_M_i.inverse. Hence we know all quantities!
            orientation = self.stQuat! * self.stDeviceMotionOffset!.inverse * orientation
        }
        cameraNode?.orientation = SCNQuaternion(orientation)
    }
}
