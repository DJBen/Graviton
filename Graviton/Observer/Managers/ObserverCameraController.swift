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
    private var stQuat: Quaternion? = nil
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
        let cnRot = cameraNode.rotation
        let rot = lastApplied.inverse * Quaternion(axisAngle: Vector4(cnRot))
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
        //]cameraNode.orientation = SCNQuaternion(derolledRot * movement)
        //cameraNode.orientation = SCNQuaternion(0, 0, 0, 1)
        print("cn \(cameraNode.orientation)")
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
            // Redefine the orientation as a rotation with respect to the Startracker-determined quaternion
            // The offset cancels whatever the device thought the quaternion was. Whatever delta rotation
            // the device thinks we did since the Startracker quaternion is then applied to the Startracker
            // quaternion
            //orientation = orientation * self.stDeviceMotionOffset!.inverse * self.stQuat!
            // TODO: go back to above!
            orientation = self.stQuat!
        }
        cameraNode?.orientation = SCNQuaternion(orientation)
    }
}
