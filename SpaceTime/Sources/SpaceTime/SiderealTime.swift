//
//  SiderealTime.swift
//  SpaceTime
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import CoreLocation
import MathUtil

public struct SiderealTime: CustomStringConvertible {
    private var offsetHours: HourAngle = 0.0

    /// Hours with fraction
    public let hourAngle: HourAngle

    public var offsetFromGreenwichMeanSiderealTime: SiderealTimeOffset {
        return SiderealTimeOffset(hourAngle: offsetHours)
    }

    public var description: String {
        let args = hourAngle.components.map { Int($0) }
        return String(format: "%02d:%02d:%02d", args[0], args[1], args[2])
    }

    public init(hourAngle: HourAngle) {
        self.hourAngle = hourAngle
    }

    public init(observerLocationTime locTime: ObserverLocationTime) {
        offsetHours = HourAngle(degreeAngle: DegreeAngle(locTime.location.coordinate.longitude))
        hourAngle = locTime.timestamp.greenwichMeanSiderealTime + offsetHours
    }

    /// Initialize Greenwich mean sidereal time at Julian day.
    ///
    /// - Parameter julianDay: The julian day.
    public init(julianDay: JulianDay) {
        hourAngle = julianDay.greenwichMeanSiderealTime
    }
}

public struct SiderealTimeOffset: CustomStringConvertible {
    /// Hours angle.
    public let hourAngle: HourAngle

    public var description: String {
        let args = hourAngle.components.map { Int($0) }
        return String(format: "\(hourAngle.sign >= 0 ? "+" : "-")%02d:%02d:%02d", args[0], args[1], args[2])
    }

    public init(hourAngle: HourAngle) {
        self.hourAngle = hourAngle
        hourAngle.wrapMode = .none
    }
}
