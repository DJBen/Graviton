//
//  HorizontalCoordinate.swift
//  SpaceTime
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import MathUtil

public struct HorizontalCoordinate: ExpressibleByDictionaryLiteral {
    public let altitude: DegreeAngle
    public let azimuth: DegreeAngle

    public init(azimuth: DegreeAngle, altitude: DegreeAngle) {
        self.azimuth = azimuth
        self.azimuth.wrapMode = .range0_360
        self.altitude = altitude
        self.altitude.wrapMode = .range_180
    }

    public init(cartesian vec: Vector3, observerInfo info: ObserverLocationTime) {
        self.init(equatorialCoordinate: EquatorialCoordinate.init(cartesian: vec), observerInfo: info)
    }

    public init(equatorialCoordinate eqCoord: EquatorialCoordinate, observerInfo info: ObserverLocationTime) {
        let radianLat = DegreeAngle(info.location.coordinate.latitude)
        let hourAngle = SiderealTime.init(observerLocationTime: info).hourAngle - eqCoord.rightAscension
        let sinAlt = sin(eqCoord.declination) * sin(radianLat) + cos(eqCoord.declination) * cos(radianLat) * cos(hourAngle)
        altitude = DegreeAngle(radianAngle: RadianAngle(asin(sinAlt)))
        altitude.wrapMode = .range_180
        let cosAzimuth = (sin(eqCoord.declination) - sinAlt * sin(radianLat)) / (cos(altitude) * cos(radianLat))
        let a = acos(cosAzimuth)
        azimuth = DegreeAngle(radianAngle: RadianAngle(sin(hourAngle) < 0 ? a : Double(2 * Double.pi) - a))
        azimuth.wrapMode = .range0_360
    }

    public init(dictionary: [String: Double]) {
        if let altDeg = dictionary["altDeg"], let aziDeg = dictionary["aziDeg"] {
            self.init(azimuth: DegreeAngle(aziDeg), altitude: DegreeAngle(altDeg))
        } else if let alt = dictionary["alt"], let azi = dictionary["azi"] {
            self.init(azimuth: DegreeAngle(radianAngle: RadianAngle(azi)), altitude: DegreeAngle(radianAngle: RadianAngle(alt)))
        } else {
            fatalError("Supply (aziDeg, altDeg) or (azi, alt) as keys when initializing HorizontalCoordinate")
        }
    }

    public init(dictionaryLiteral elements: (String, Double)...) {
        var dict = [String: Double]()
        elements.forEach { dict[$0.0] = $0.1 }
        self.init(dictionary: dict)
    }
}

public extension EquatorialCoordinate {

    /// Initialize an equatorial coordinate from horizontal coordinate 
    /// with distance defaulting to 1.
    ///
    /// - Parameters:
    ///   - coord: horizontal coordinate
    ///   - info: location and time information about the observer
    public init(horizontalCoordinate coord: HorizontalCoordinate, observerInfo info: ObserverLocationTime) {
        let latitude = DegreeAngle(info.location.coordinate.latitude)
        let sinDec = sin(coord.altitude) * sin(latitude) + cos(coord.altitude) * cos(latitude) * cos(coord.azimuth)
        let dec = DegreeAngle(radianAngle: RadianAngle(asin(sinDec)))
        let sinLha = -sin(coord.azimuth) * cos(coord.altitude) / cos(dec)
        let cosLha = (sin(coord.altitude) - sin(latitude) * sin(dec)) / (cos(dec) * cos(latitude))
        let lha = HourAngle(radianAngle: RadianAngle(atan2(sinLha, cosLha)))
        let ra = SiderealTime.init(observerLocationTime: info).hourAngle - lha
        self.init(rightAscension: ra, declination: dec, distance: 1)
    }
}
