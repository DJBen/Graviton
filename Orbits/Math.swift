//
//  swift
//  Orbits
//
//  Created by Ben Lu on 9/15/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit

// wrap angle from 0 to 2π
func wrapAngle(_ angle: Float) -> Float {
    let twoPi = Float(M_PI * 2)
    var wrapped = fmod(angle, twoPi)
    if wrapped < 0.0 {
        wrapped += twoPi
    }
    return wrapped
}

func calculatePeriod(semimajorAxis a: Float, gravParam: Float) -> Float {
    return Float(M_PI) * 2 * sqrt(pow(a, 3) / gravParam)
}


/// Calculate mean anomaly from time
///
/// - Parameters:
///   - time: time since JD2000 in seconds
///   - gravParam: gravity parameter
///   - shape: shape of orbit
/// - Returns: mean anomaly of current orbit motion
func calculateMeanAnomaly(Δt time: Float, gravParam: Float, shape: Orbit.ConicSection) -> Float? {
    switch shape {
    case .circle(let a), .ellipse(let a, _), .hyperbola(let a, _):
        return wrapAngle(time * sqrt(gravParam / pow(a, 3)))
    case .parabola(_):
        return nil
    }
}

func calculateTrueAnomaly(eccentricity: Float, eccentricAnomaly: Float) -> Float {
    return 2 * atan2(sqrt(1 + eccentricity) * sin(eccentricAnomaly / 2), sqrt(1 - eccentricity) * cos(eccentricAnomaly / 2))
}
