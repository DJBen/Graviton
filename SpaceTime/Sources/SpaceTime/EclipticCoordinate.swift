//
//  EclipticCoordinate.swift
//  SpaceTime
//
//  Created by Sihao Lu on 12/26/17.
//  Copyright © 2017 Sihao. All rights reserved.
//

import Foundation
import MathUtil

public struct EclipticCoordinate {

    public let longitude: DegreeAngle
    public let latitude: DegreeAngle
    public let distance: Double

    public let julianDay: JulianDay

    public init(longitude: DegreeAngle, latitude: DegreeAngle, distance: Double, julianDay: JulianDay) {
        self.latitude = latitude
        self.longitude = longitude
        self.latitude.wrapMode = .range_180
        self.longitude.wrapMode = .range_180
        self.julianDay = julianDay
        self.distance = distance
    }

    /// Initialize ecliptical coordinate using the *true*, or apparent obliquity
    /// of the ecliptic.
    ///
    /// There are two exceptions: if referred against the standard equinox of J2000.0,
    /// the value of obliquity of ecliptic ε = 23°26′21″.448 = 23°.4392911 is used.
    /// For the standard equinox of B1950.0, we have ε_1950 = 23°.4457889.
    ///
    /// - Parameters:
    ///   - coord: The equatorial coordinate.
    ///   - julianDay: The julian day.
    public init(equatorialCoordinate coord: EquatorialCoordinate, julianDay: JulianDay) {
        let ε = EclipticUtil.obliquityOfEcliptic(julianDay: julianDay)
        longitude = DegreeAngle(radianAngle: RadianAngle(atan2(sin(coord.rightAscension) * cos(ε) + tan(coord.declination) * sin(ε), cos(coord.rightAscension))))
        latitude = DegreeAngle(radianAngle: RadianAngle(asin(sin(coord.declination) * cos(ε) - cos(coord.declination) * sin(ε) * sin(coord.rightAscension))))
        latitude.wrapMode = .range_180
        longitude.wrapMode = .range_180
        distance = coord.distance
        self.julianDay = julianDay
    }
}

public extension EquatorialCoordinate {

    /// Initialize ecliptical coordinate using the *true*, or apparent obliquity
    /// of the ecliptic.
    ///
    /// There are two exceptions: if referred against the standard equinox of J2000.0,
    /// the value of obliquity of ecliptic ε = 23°26′21″.448 = 23°.4392911 is used.
    /// For the standard equinox of B1950.0, we have ε_1950 = 23°.4457889.
    ///
    /// - Parameters:
    ///   - coord: The equatorial coordinate.
    ///   - julianDay: The julian day.
    public init(EclipticCoordinate coord: EclipticCoordinate, julianDay: JulianDay) {
        // TODO: support precession
        precondition(julianDay == coord.julianDay, "only conversion from ecliptical to equatorial coordinate of the same equinox is supported")
        let ε = EclipticUtil.obliquityOfEcliptic(julianDay: julianDay)
        rightAscension = HourAngle(radianAngle: RadianAngle(atan2(sin(coord.longitude) * cos(ε) - tan(coord.latitude) * sin(ε), cos(coord.longitude))))
        declination = DegreeAngle(radianAngle: RadianAngle(asin(sin(coord.latitude) * cos(ε) + cos(coord.latitude) * sin(ε) * sin(coord.longitude))))
        distance = coord.distance
    }
}
