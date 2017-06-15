//
//  AttitudeStabilizer.swift
//  Graviton
//
//  Created by Sihao Lu on 6/14/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import CoreMotion
import MathUtil

class AttitudeStabilizer {
    // Number of samples involved in smoothing calculation. The greater this value, the smoother the camera, the greater the lag.
    var sampleTimeWindow: TimeInterval = 10 / 60

    /// When camera's angular motion exceeds this angular velocity (in radians per second),
    /// this motion sample is discarded and does not involve in smoothing calculations.
    /// The smaller this value, the smaller lagging is percepted during quick motion.
    var angularVelocityThreshold = radians(degrees: 3)
    var angularSeparationThreshold = radians(degrees: 0.5)

    private var motions = [CMDeviceMotion]()

    private var quaternion: Quaternion?

    func addDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        motions = Array(motions.prefix(while: { deviceMotion.timestamp - $0.timestamp <= sampleTimeWindow }))
        motions.append(deviceMotion)
    }

    var smoothedQuaternion: Quaternion {
        var lastTimestamp: TimeInterval?
        if quaternion == nil {
            if let qt = motions.last?.attitude.quaternion {
                quaternion = Quaternion(qt)
            } else {
                quaternion = .identity
            }
        }
        var averagedQuaternion: Quaternion?
        // considering motions from most recent to least recent
        for motion in motions.reversed() {
            if averagedQuaternion == nil {
                averagedQuaternion = Quaternion(motion.attitude.quaternion)
                lastTimestamp = motion.timestamp
                continue
            }
            let newQuaternion = Quaternion(motion.attitude.quaternion)
            // drop out outliers
            if abs((newQuaternion * averagedQuaternion!.inverse).toAxisAngle().w) > angularVelocityThreshold * abs(motion.timestamp - lastTimestamp!) {
                continue
            }
            averagedQuaternion = averagedQuaternion!.interpolated(with: newQuaternion, by: 0.5)
        }
        if abs((quaternion! * averagedQuaternion!.inverse).toAxisAngle().w) > angularSeparationThreshold {
            quaternion = averagedQuaternion
        }
        return quaternion!
    }
}
