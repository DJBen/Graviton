//
//  SiderealTime.swift
//  SpaceTime
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import CoreLocation

public extension JulianDate {
    /// GMST in hours and fraction of an hour
    public var greenwichMeanSiderealTime: Double {
        let diff = value - JulianDate.J2000.value
        // magic function comes from
        // https://en.wikipedia.org/wiki/Sidereal_time
        let GMST = 18.697374558 + 24.06570982441908 * diff
        return GMST.truncatingRemainder(dividingBy: 24)
    }

}
