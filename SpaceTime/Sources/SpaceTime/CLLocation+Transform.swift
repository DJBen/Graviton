//
//  CLLocation+Transform.swift
//  Graviton
//
//  Created by Sihao Lu on 6/15/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import MathUtil

// MARK: - Coordinate Transformations
public extension CLLocation {
    public var ecefCoordinate: Vector3 {
        // equatorial radius
        let R_Ea: Double = 6378137
        // meridian radius
        let R_Eb: Double = 6356752
        let e = sqrt(R_Ea * R_Ea - R_Eb * R_Eb) / R_Ea
        let φ = RadianAngle(degreeAngle: DegreeAngle(coordinate.latitude)).value
        let λ = RadianAngle(degreeAngle: DegreeAngle(coordinate.longitude)).value
        let Ne = R_Ea / sqrt(1 - e * e * pow(sin(φ), 2))
        return Vector3(
            (Ne + altitude) * cos(φ) * cos(λ),
            (Ne + altitude) * cos(φ) * sin(λ),
            (Ne * (1 - e * e) + altitude) * sin(φ)
        )
    }

    /// The transform that rotates ECEF coordinate to NED coordinate at given timestamp and location
    public var ecefToLocalNedTransform: Matrix4 {
        let φ = RadianAngle(degreeAngle: DegreeAngle(coordinate.latitude)).value
        let λ = RadianAngle(degreeAngle: DegreeAngle(coordinate.longitude)).value
        return Matrix4(rotation: Vector4(0, 1, 0, φ + Double.pi / 2)) * Matrix4(rotation: Vector4(0, 0, 1, -λ))
    }

    // UNTESTED
    var ecefToLocalEnuTransform: Matrix4 {
        let φ = RadianAngle(degreeAngle: DegreeAngle(coordinate.latitude)).value
        let λ = RadianAngle(degreeAngle: DegreeAngle(coordinate.longitude)).value
        return Matrix4(rotation: Vector4(1, 0, 0, Double.pi / 2 - φ)) * Matrix4(rotation: Vector4(0, 0, 1, Double.pi / 2 + λ))
    }
}
