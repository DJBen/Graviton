//
//  JulianDay.swift
//  Orbits
//
//  Created by Ben Lu on 11/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import MathUtil

fileprivate let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}()

public struct JulianDay: CustomStringConvertible, ExpressibleByFloatLiteral, Comparable {

    public typealias FloatLiteralType = Double

    public static let B1950: JulianDay = 2433282.4235
    public static let J2000: JulianDay = 2451545.0

    public static var now: JulianDay {
        return JulianDay(date: Date())
    }

    public var description: String {
        return "<\(date), JD \(value)>"
    }

    public let value: Double

    /// Difference between earth rotation time and terrestrial time.
    /// It is derived from observation only and is reported in this
    /// bulletin: http://maia.usno.navy.mil/ser7/ser7.dat,
    /// where deltaT = 32.184 + (TAI-UTC) - DUT1
    public var deltaT: Double

    public var modifiedJulianDay: Double {
        return value - 2400000.5
    }

    public var julianCentury: Double {
        return (value - 2451545.0) / 36525.0
    }

    public var julianEphemerisDay: Double {
        return value + deltaT / 86400.0
    }

    public var julianEphemerisCentury: Double {
        return (julianEphemerisDay - 2451545.0) / 36525.0
    }

    public var julianEphemerisMillennium: Double {
        return julianEphemerisCentury / 10.0
    }

    public init(_ value: FloatLiteralType, deltaT: Double = 0) {
        self.value = value
        self.deltaT = deltaT
    }

    public init(floatLiteral value: FloatLiteralType) {
        self.value = value
        self.deltaT = 0
    }

    public init(date: Date, deltaT: Double = 0) {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = components.year!
        let month = components.month!
        let day = components.day!
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        let a: Double = floor(Double(14 - month) / 12)
        let y: Double = Double(year) - a + 4800
        let m: Double = Double(month) + 12 * a - 3
        var JDN: Double = Double(day) + y * 365 - 32045
        JDN += floor((153 * m + 2) / 5)
        JDN += floor(y / 4) - floor(y / 100) + floor(y / 400)
        value = JDN + Double(hour - 12) / 24 + Double(minute) / 1440 + Double(second) / 86400
        self.deltaT = deltaT
    }

    public var date: Date {
        let JD = value
        var L = Int(modf(JD).1 > 0.5 ? JD + 0.5 : JD) + 68569
        let N = 4 * L / 146097
        L = L - (146097 * N + 3) / 4
        var I = 4000 * (L + 1) / 1461001
        L = L - 1461 * I / 4 + 31
        var J = 80 * L / 2447
        let K = L - 2447 * J / 80
        L = J / 11
        J = J + 2 - 12 * L
        I = 100 * (N - 49) + I + L
        var frac = (modf(JD).1 > 0.5 ? modf(JD).1 - 0.5 : modf(JD).1 + 0.5) * 86400
        let hour = Int(frac / 3600)
        frac -= Double(hour * 3600)
        let minute = Int(frac / 60)
        frac -= Double(minute * 60)
        let second = Int(frac)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dateComponents = DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0)!,
            year: I,
            month: J,
            day: K,
            hour: hour,
            minute: minute,
            second: second
        )
        return dateComponents.date!
    }

    public static func +(lhs: JulianDay, rhs: TimeInterval) -> JulianDay {
        return JulianDay(lhs.value + rhs / 86400)
    }

    public static func -(lhs: JulianDay, rhs: TimeInterval) -> JulianDay {
        return JulianDay(lhs.value - rhs / 86400)
    }

    /// Difference in fractional seconds between Julian dates
    ///
    /// - Parameters:
    ///   - lhs: Julian date
    ///   - rhs: Julian date to be subtracted
    /// - Returns: The difference between two Julian dates in fractional seconds
    public static func -(lhs: JulianDay, rhs: JulianDay) -> TimeInterval {
        // convert day to seconds
        return (lhs.value - rhs.value) * 86400
    }

    public static func ~=(lhs: JulianDay, rhs: JulianDay) -> Bool {
        return lhs.value ~= rhs.value
    }

    public static func ==(lhs: JulianDay, rhs: JulianDay) -> Bool {
        return lhs.value == rhs.value
    }

    /// Compare two julian dates.
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func <(lhs: JulianDay, rhs: JulianDay) -> Bool {
        return lhs.value < rhs.value
    }
}

extension JulianDay {
    /// GMST in hours and fraction of an hour
    var greenwichMeanSiderealTime: HourAngle {
        let diff = value - JulianDay.J2000.value
        // magic function comes from
        // https://en.wikipedia.org/wiki/Sidereal_time
        let gmst = 18.697374558 + 24.06570982441908 * diff
        return HourAngle(gmst.truncatingRemainder(dividingBy: 24))
    }
}

extension Optional where Wrapped == JulianDay {
    public static func ~=(lhs: JulianDay?, rhs: JulianDay?) -> Bool {
        if lhs == rhs {
            return true
        }
        if (lhs == nil && rhs != nil) || (lhs != nil && rhs == nil) {
            return false
        }
        return lhs!.value ~= rhs!.value
    }
}
