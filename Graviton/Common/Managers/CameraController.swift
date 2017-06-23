//
//  CameraController.swift
//  Graviton
//
//  Created by Sihao Lu on 6/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import MathUtil

class CameraController: NSObject {
    struct Invert: OptionSet {
        let rawValue: Int
        static let none = Invert(rawValue: 0)
        static let invertPitch = Invert(rawValue: 1)
        static let invertYaw = Invert(rawValue: 1 << 1)
        static let invertRoll = Invert(rawValue: 1 << 2)
        static let invertAll: Invert = [.invertPitch, .invertYaw, .invertRoll]
    }

    var cameraInversion: Invert = .none
    var viewSlideDivisor: CGFloat = 5000
    var viewSlideVelocityCap: CGFloat = 800
    var viewSlideInertiaDuration: TimeInterval = 1
    weak var cameraNode: SCNNode?

    var slideVelocity: CGPoint = CGPoint()
    var referenceSlideVelocity: CGPoint = CGPoint()
    var slidingStopTimestamp: TimeInterval?
    var rotation: CGFloat = 0
    var previousRotation: SCNVector4?
    var previousScale: Double?

    static var `default` = CameraController()

    /// Unit 3d coordinate in the center of the screen
    var center: Vector3 {
        fatalError("unimplemented")
    }

    var cameraYaw: Double {
        var yaw = Double(-slideVelocity.x / viewSlideDivisor)
        if cameraInversion.contains(.invertYaw) {
            yaw = -yaw
        }
        return yaw
    }

    var cameraPitch: Double {
        var pitch = Double(-slideVelocity.y / viewSlideDivisor)
        if cameraInversion.contains(.invertPitch) {
            pitch = -pitch
        }
        return pitch
    }

    /// Decelerate the amera by attenuating slide velocity.
    ///
    /// - Parameter time: The timestamp
    func decelerateCamera(atTime time: TimeInterval) {
        if let ts = slidingStopTimestamp {
            let p = min((time - ts) / viewSlideInertiaDuration, 1) - 1
            let factor: CGFloat = CGFloat(-p * p * p)
            slideVelocity = CGPoint(x: referenceSlideVelocity.x * factor, y: referenceSlideVelocity.y * factor)
        } else {
            slidingStopTimestamp = time
        }
    }

    // http://stackoverflow.com/questions/25654772/rotate-scncamera-node-looking-at-an-object-around-an-imaginary-sphere
    func handleCameraPan(atTime time: TimeInterval) {
        guard let cameraNode = cameraNode else { return }
        let rot = Quaternion(axisAngle: Vector4(cameraNode.rotation))
        let yaw = Quaternion(axisAngle: Vector4(0, 1, 0, cameraYaw))
        let pitch = Quaternion(axisAngle: Vector4(1, 0, 0, cameraPitch))
        let cameraMovement = pitch * yaw
        let finalRot = rot * cameraMovement
        precondition(finalRot.length ~= 1)
        cameraNode.orientation = SCNQuaternion(finalRot)
        decelerateCamera(atTime: time)
    }

    func handleCameraRotation(atTime time: TimeInterval) {
        guard let cameraNode = cameraNode, let oldRot = previousRotation else { return }
        var rot: GLKQuaternion = GLKQuaternionMakeWithAngleAndAxis(oldRot.w, oldRot.x, oldRot.y, oldRot.z)
        var rotZ: GLKQuaternion = GLKQuaternionMakeWithAngleAndAxis(Float(rotation), 0, 0, 1)
        if cameraInversion.contains(.invertRoll) {
            rotZ = GLKQuaternionInvert(rotZ)
        }
        rot = GLKQuaternionMultiply(rot, rotZ)

        let axis = GLKQuaternionAxis(rot)
        let angle = GLKQuaternionAngle(rot)
        cameraNode.rotation = SCNVector4Make(axis.x, axis.y, axis.z, angle)
    }
}
