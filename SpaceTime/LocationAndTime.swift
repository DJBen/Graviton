//
//  LocationAndTime.swift
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
public struct LocationAndTime {
    public let location: CLLocation
    public var timestamp: Date

    public init() {
        self.location = CLLocation()
        self.timestamp = Date()
    }

    public init(location: CLLocation, timestamp: Date?) {
        self.location = location
        self.timestamp = timestamp ?? location.timestamp
    }

    /// local sidereal time as hour angle in radians.
    public var localSiderealTimeAngle: Double {
        let hours = location.coordinate.longitude / 15
        let siderealTime = timestamp.greenwichMeanSiderealTime + hours
        return wrapAngle(siderealTime / 12 * Double.pi)
    }

    /// The transformation from celestial coordinate (RA, DEC) to North-East-Down coordinate (azi, elev) at the given ECEF coordinate (lat, lon) at the current time.
    public var localViewTransform: Matrix4 {
        return location.ecefToLocalNedTransform * Matrix4.init(rotation: Vector4(0, 0, 1, -radians(hours: timestamp.greenwichMeanSiderealTime)))
    }
}
