//
//  CameraControlling.swift
//  Graviton
//
//  Created by Sihao Lu on 1/8/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SceneKit
import MathUtil

protocol CameraControlling {
    var cameraNode: SCNNode { get }
    var gestureOrientation: Quaternion { get }
    var scale: Double { get set }
    func resetCamera()
}
