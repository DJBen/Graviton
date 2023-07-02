//
//  ObserverLocationTime.swift
//  SpaceTime
//
//  Created by Sihao Lu on 1/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import Foundation
import MathUtil

/// This struct encloses a referential timestamp and a location.
///
/// **Note**: The meaning of timestamp is foundamentally different from the `timestamp` in CLLocation, which in turns specifies the timestamp the location is measured.
public struct ObserverLocationTime {
    public let location: CLLocation
    public var timestamp: JulianDay

    public init() {
        self.location = CLLocation()
        self.timestamp = JulianDay.now
    }

    public init(location: CLLocation, timestamp: JulianDay?) {
        self.location = location
        self.timestamp = timestamp ?? JulianDay(date: location.timestamp)
    }

    /// The transformation from celestial coordinate (RA, DEC) to North-East-Down coordinate (azi, elev) at the given ECEF coordinate (lat, lon) at the current time.
    public var localViewTransform: Matrix4 {
        let hourAngle = SiderealTime(julianDay: timestamp).hourAngle
        return location.ecefToLocalNedTransform * Matrix4.init(rotation: Vector4(0, 0, 1, -RadianAngle(hourAngle: hourAngle).wrappedValue))
    }
}
