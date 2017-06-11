//
//  EulerAngle.swift
//  Graviton
//
//  Created by Sihao Lu on 6/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import MathUtil

public struct EulerAngle: Equatable {
    public var yaw: Double
    public var pitch: Double
    public var roll: Double

    public init(yaw: Double, pitch: Double, roll: Double) {
        self.yaw = wrapAngle(yaw)
        self.pitch = wrapAngle(pitch)
        self.roll = wrapAngle(roll)
    }

    public static func ==(lhs: EulerAngle, rhs: EulerAngle) -> Bool {
        return lhs.yaw == rhs.yaw && lhs.pitch == rhs.pitch && lhs.roll == rhs.roll
    }

    public static func ~=(lhs: EulerAngle, rhs: EulerAngle) -> Bool {
        return lhs.yaw ~= rhs.yaw && lhs.pitch ~= rhs.pitch && lhs.roll ~= rhs.roll
    }
}

// https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
public extension EulerAngle {
    public init(quaternion q: Quaternion) {
        let ysqr = q.y * q.y

        // roll (x-axis rotation)
        let t0 = 2.0 * (q.w * q.x + q.y * q.z)
        let t1 = 1.0 - 2.0 * (q.x * q.x + ysqr)
        roll = wrapAngle(atan2(t0, t1))

        // pitch (y-axis rotation)
        var t2 = 2.0 * (q.w * q.y - q.z * q.x)
        t2 = t2 > 1.0 ? 1.0 : t2
        t2 = t2 < -1.0 ? -1.0 : t2
        pitch = wrapAngle(asin(t2))

        // yaw (z-axis rotation)
        let t3 = 2.0 * (q.w * q.z + q.x * q.y)
        let t4 = 1.0 - 2.0 * (ysqr + q.z * q.z)
        yaw = wrapAngle(atan2(t3, t4))
    }
}

public extension Quaternion {
    public init(eulerAngle eu: EulerAngle) {
        let t0 = cos(eu.yaw * 0.5)
        let t1 = sin(eu.yaw * 0.5)
        let t2 = cos(eu.roll * 0.5)
        let t3 = sin(eu.roll * 0.5)
        let t4 = cos(eu.pitch * 0.5)
        let t5 = sin(eu.pitch * 0.5)

        w = t0 * t2 * t4 + t1 * t3 * t5
        x = t0 * t3 * t4 - t1 * t2 * t5
        y = t0 * t2 * t5 + t1 * t3 * t4
        z = t1 * t2 * t4 - t0 * t3 * t5
    }
}
