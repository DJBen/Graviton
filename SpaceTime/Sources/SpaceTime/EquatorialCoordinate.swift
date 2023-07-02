//
//  EquatorialCoordinate.swift
//  SpaceTime
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import MathUtil

public struct EquatorialCoordinate: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Double

    public let distance: Double

    /// Right ascension, ranged from 0h to 24h.
    public let rightAscension: HourAngle

    /// Declination measured north or south of the celestial equator, ranged from -90° to 90°.
    public let declination: DegreeAngle


    /// Initialize equatorial coordinate with cartesian vector defined as follows.
    ///
    /// - +x towards α = 0 degrees, α = 0.0 hours (the vernal equinox)
    /// - +y towards δ = 0 degrees, α = 6.0 hours
    /// - +z: towards δ = +90.0 degrees (north celestial pole)
    ///
    /// - Parameter cartesian: The cartesian vector.
    /// - seealso: http://www.geom.uiuc.edu/docs/reference/CRC-formulas/node42.html
    public init(cartesian vec: Vector3) {
        distance = sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
        declination = DegreeAngle(radianAngle: RadianAngle(Double.pi / 2 - acos(vec.z / distance)))
        declination.wrapMode = .range_180
        rightAscension = HourAngle(radianAngle: RadianAngle(atan2(vec.y, vec.x)))
    }

    public init(rightAscension: HourAngle, declination: DegreeAngle, distance: Double) {
        self.rightAscension = rightAscension
        self.declination = declination
        self.distance = distance
        self.declination.wrapMode = .range_180
    }

    public init(dictionary: [String: Double]) {
        if let raDeg = dictionary["raDeg"], let decDeg = dictionary["decDeg"] {
            self.init(rightAscension: HourAngle(degreeAngle: DegreeAngle(raDeg)), declination: DegreeAngle(decDeg), distance: 1)
        } else if let ra = dictionary["ra"], let dec = dictionary["dec"] {
            self.init(rightAscension: HourAngle(radianAngle: RadianAngle(ra)), declination: DegreeAngle(radianAngle: RadianAngle(dec)), distance: 1)
        } else {
            fatalError("Supply (raDeg, decDeg) or (ra, dec) as keys when initializing EquatorialCoordinate")
        }
    }

    public init(dictionaryLiteral elements: (String, Double)...) {
        var dict = [String: Double]()
        elements.forEach { dict[$0.0] = $0.1 }
        self.init(dictionary: dict)
    }
}

public extension Vector3 {
    /// Initialize a Cartesian with equatorial coordinate.
    ///
    /// - +x towards α = 0 degrees, α = 0.0 hours (the vernal equinox)
    /// - +y towards δ = 0 degrees, α = 6.0 hours
    /// - +z: towards δ = +90.0 degrees (north celestial pole)
    ///
    /// - Parameter coord: The equatorial coordinate
    public init(equatorialCoordinate coord: EquatorialCoordinate) {
        self.init(
            coord.distance * cos(coord.declination) * cos(coord.rightAscension),
            coord.distance * cos(coord.declination) * sin(coord.rightAscension),
            coord.distance * sin(coord.declination)
        )
    }
}

public extension EquatorialCoordinate {
    //
    // ra1, dec1: RA, dec coordinates, in radians, for EPOCH1, where the epoch is in years AD.
    // Output: [RA, dec], in radians, precessed to EPOCH2, where the epoch is in years AD.
    //
    // Original comment:
    // Herget precession, see p. 9 of Publ. Cincinnati Obs., No. 24.
    //
    func precessed(from epoch1: Double, to epoch2: Double) -> EquatorialCoordinate {
        let (ra1, dec1) = (rightAscension, declination)
        var a, b, c: Double
        let cdr = Double.pi / 180.0
        let csr = cdr / 3600.0
        a = cos(dec1)
        let x1 = Vector3(a * cos(ra1), a * sin(ra1), sin(dec1))
        let t = 0.001 * (epoch2 - epoch1)
        let st = 0.001 * (epoch1 - 1900.0)
        a = csr * t * (23042.53 + st * (139.75 + 0.06 * st) + t * (30.23 - 0.27 * st + 18.0 * t))
        b = csr * t * t * (79.27 + 0.66 * st + 0.32 * t) + a
        c = csr * t * (20046.85 - st * (85.33 + 0.37 * st) + t * (-42.67 - 0.37 * st - 41.8 * t))
        let r = Matrix3.init(
            cos(a) * cos(b) * cos(c) - sin(a) * sin(b),
            -cos(a) * sin(b) - sin(a) * cos(b) * cos(c),
            -cos(b) * sin(c),
            sin(a) * cos(b) + cos(a) * sin(b) * cos(c),
            cos(a) * cos(b) - sin(a) * sin(b) * cos(c),
            -sin(b) * sin(c),
            cos(a) * sin(c),
            -sin(a) * sin(c),
            cos(c)
        ).transpose
        let x2 = r * x1
        return EquatorialCoordinate(rightAscension: HourAngle(radianAngle: RadianAngle(atan2(x2.y, x2.x))), declination: DegreeAngle(radianAngle: RadianAngle(asin(x2.z))), distance: distance)
    }

    public func angularSeparation(from coord: EquatorialCoordinate) -> DegreeAngle {
        // use special case of the Vincenty formula for an ellipsoid with equal major and minor axes for greater accuracy
        let (α1, α2, δ1, δ2) = (rightAscension, coord.rightAscension, declination, coord.declination)
        let t1 = pow(cos(δ2) * sin(α2 - α1), 2)
        let t2 = pow(cos(δ1) * sin(δ2) - sin(δ1) * cos(δ2) * cos(α2 - α1), 2)
        let denom = sin(δ1) * sin(δ2) + cos(δ1) * cos(δ2) * cos(α2 - α1)
        return DegreeAngle(radianAngle: RadianAngle(atan2(sqrt(t1 + t2), denom)))
    }
}
