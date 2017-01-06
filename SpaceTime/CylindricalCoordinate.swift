//
//  CylindricalCoordinate.swift
//  Graviton
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation

public struct CylindricalCoordinate {
    let altitude: Float
    let azimuth: Float
    
    public init(sphericalCoordinate s: SphericalCoordinate, observerInfo o: ObserverInfo) {
        // sin(ALT) = sin(DEC)*sin(LAT)+cos(DEC)*cos(LAT)*cos(HA)
        let radianLat = radians(degrees: Float(o.location.latitude))
        let hourAngle = o.localSiderealTimeAngle - s.rightAscension
        let sinAlt = sin(s.declination) * sin(radianLat) + cos(s.declination) * cos(radianLat) * cos(hourAngle)
        altitude = asin(sinAlt)
        //                sin(DEC) - sin(ALT)*sin(LAT)
        // cos(A)   =   ---------------------------------
        //                cos(ALT)*cos(LAT)
        let cosAzimuth = (sin(s.declination) - sinAlt * sin(radianLat)) / (cos(altitude) * cos(radianLat))
        let a = acos(cosAzimuth)
        azimuth = sin(hourAngle) < 0 ? a : Float(2 * M_PI) - a
    }
}
