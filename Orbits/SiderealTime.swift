//
//  SiderealTime.swift
//  Graviton
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import CoreLocation

public extension Date {
    
    /// GMST in hours and fraction of an hour
    public var greenwichMeanSiderealTime: Double {
        let diff = self.julianDate - JulianDate.J2000
        // magic function comes from
        // https://en.wikipedia.org/wiki/Sidereal_time
        let GMST = 18.697374558 + 24.06570982441908 * diff
        return GMST.truncatingRemainder(dividingBy: 24)
    }
    
    public func localSiderealTime(coordinate: CLLocationCoordinate2D) -> Double {
        let hours = coordinate.longitude / 15
        return greenwichMeanSiderealTime + hours
    }
}

