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
    override func handleCameraPan(atTime time: TimeInterval) {
        guard let cameraNode = cameraNode else { return }
        let rot = Quaternion(axisAngle: Vector4(cameraNode.rotation))
        let finalRot = rot * cameraMovement
        precondition(finalRot.length ~= 1)
        cameraNode.orientation = SCNQuaternion(finalRot)
        fadeOutCameraMovement(atTime: time)
    }
}
