//
//  ObserverInfo.swift
//  SpaceTime
//
//  Created by Sihao Lu on 1/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import Foundation
import MathUtil

public struct ObserverInfo {
    public let location: CLLocation
    public var timestamp: Date

    public init(location: CLLocation, timestamp: Date?) {
        self.location = location
        self.timestamp = timestamp ?? location.timestamp
    }

    /// local sidereal time in radians
    public var localSiderealTimeAngle: Double {
        let hours = location.coordinate.longitude / 15
        let siderealTime = timestamp.greenwichMeanSiderealTime + hours
        return wrapAngle(siderealTime / 12 * Double.pi)
    }

    public var localViewTransform: Matrix4 {
        return location.ecefToLocalNedTransform * Matrix4.init(rotation: Vector4(0, 0, 1, -radians(hours: timestamp.greenwichMeanSiderealTime)))
    }
}

// MARK: - Coordinate Transformations
extension CLLocation {
    var ecefCoordinate: Vector3 {
        // equatorial radius
        let R_Ea: Double = 6378137
        // meridian radius
        let R_Eb: Double = 6356752
        let e = sqrt(R_Ea * R_Ea - R_Eb * R_Eb) / R_Ea
        let φ = radians(degrees: coordinate.latitude)
        let λ = radians(degrees: coordinate.longitude)
        let Ne = R_Ea / sqrt(1 - e * e * pow(sin(φ), 2))
        return Vector3(
            (Ne + altitude) * cos(φ) * cos(λ),
            (Ne + altitude) * cos(φ) * sin(λ),
            (Ne * (1 - e * e) + altitude) * sin(φ)
        )
    }

    var ecefToLocalNedTransform: Matrix4 {
        let φ = radians(degrees: coordinate.latitude)
        let λ = radians(degrees: coordinate.longitude)
        return Matrix4(
            -sin(φ) * cos(λ), -sin(φ) * sin(λ), cos(φ), 0,
            -sin(λ), cos(λ), 0, 0,
            -cos(φ) * cos(λ), -cos(φ) * sin(λ), -sin(φ), 0,
            0, 0, 0, 1
        ).transpose
    }

    var ecefToLocalEnuTransform: Matrix4 {
        let φ = radians(degrees: coordinate.latitude)
        let λ = radians(degrees: coordinate.longitude)
        return Matrix4.init(rotation: Vector4(1, 0, 0, Double.pi / 2 - φ)) * Matrix4.init(rotation: Vector4(0, 0, 1, Double.pi / 2 + λ))
    }
}
