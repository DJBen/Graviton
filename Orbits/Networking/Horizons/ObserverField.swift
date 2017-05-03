//
//  HorizonsField.swift
//  Graviton
//
//  Created by Ben Lu on 5/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

public extension HorizonsQuery {
    public struct ObserverField: OptionSet {
        // There are 43 values up to date, so we need a 64-bit integer
        public let rawValue: UInt64

        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }

        /// J2000.0 astrometric right ascension and declination of target center.
        /// Adjusted for light-time. Units: HMS (HH MM SS.ff) and DMS (DD MM SS.f)
        public static let astrometricRaAndDec = ObserverField(rawValue:  1 << 1)

        /// Moon's approximate apparent visual magnitude & surface brightness. When
        /// phase angle < 7 deg (within ~ 1 day of full Moon), computed magnitude tends to
        /// be about 0.12 too small.
        /// Units: MAGNITUDE & VISUAL MAGNITUDES PER SQUARE ARCSECOND
        public static let visualMagnitudeAndSurfaceBrightness = ObserverField(rawValue: 1 << 9)

        /// Fraction of target circular disk illuminated by Sun (phase), as seen by
        /// observer.  Units: PERCENT
        public static let illuminatedFraction = ObserverField(rawValue: 1 << 10)

        /// The equatorial angular width of the target body full disk, if it were
        /// fully visible to the observer.  Units: ARCSECONDS
        public static let targetAngularDiameter = ObserverField(rawValue: 1 << 13)

        /// Apparent planetodetic longitude and latitude (IAU2009 model) of the center
        /// of the target disc seen by the OBSERVER at print-time. This is NOT exactly the
        /// same as the "sub-observer" (nearest) point for a non-spherical target shape,
        /// but is generally very close if not a very irregular body shape. Down-leg light
        /// travel-time from target to observer is taken into account. Latitude is the
        /// angle between the equatorial plane and the line perpendicular to the reference
        /// ellipsoid of the body. The reference ellipsoid is an oblate spheroid with a
        /// single flatness coefficient in which the y-axis body radius is taken to be the
        /// same value as the x-axis radius. Positive longitude is to the EAST.
        /// Units: DEGREES
        public static let observerSubLongitudeAndSubLatitude = ObserverField(rawValue: 1 << 14)

        /// Apparent planetodetic longitude and latitude of the Sun (IAU2009) as seen by
        /// the observer at print-time.  This is NOT exactly the same as the "sub-solar"
        /// (nearest) point for a non-spherical target shape, but is generally very close
        /// if not an irregular body shape. Light travel-time from Sun to target and from
        /// target to observer is taken into account.  Latitude is the angle between the
        /// equatorial plane and the line perpendicular to the reference ellipsoid of the
        /// body. The reference ellipsoid is an oblate spheroid with a single flatness
        /// coefficient in which the y-axis body radius is taken to be the same value as
        /// the x-axis radius. Positive longitude is to the EAST.  Units: DEGREES
        public static let sunSubLongitudeAndSubLatitude = ObserverField(rawValue: 1 << 15)

        /// ICRF/J2000.0 Right Ascension and Declination (IAU2009 rotation model)
        /// of target body's North Pole direction at the time light left the body to
        /// be observed at print time. Units: DEGREES
        public static let northPoleRaAndDec = ObserverField(rawValue: 1 << 32)

        /// Generated quantity string for JPL Horizons
        public var quantities: String {
            return (0..<64).flatMap { 1 & rawValue >> UInt64($0) == 1 ? String($0) : nil }.joined(separator: ",")
        }

        public static let geocentricObserverFields: ObserverField = [
            astrometricRaAndDec,
            visualMagnitudeAndSurfaceBrightness,
            illuminatedFraction,
            targetAngularDiameter,
            observerSubLongitudeAndSubLatitude,
            sunSubLongitudeAndSubLatitude,
            northPoleRaAndDec
        ]
    }
}
