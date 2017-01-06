//
//  JulianDate.swift
//  Orbits
//
//  Created by Ben Lu on 11/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

public struct JulianDate {
    public static let B1950: Double = 2433282.4235
    public static let J2000: Double = 2451545.0
    
    public let value: Double
    
    public init(value: Double) {
        self.value = value
    }
    
    public init(date: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
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
    }
    
    public var date: Date {
        let (y, j, m, n, r, p) = (4716, 1401, 2, 12, 4, 1461)
        let (v, u, s, w, B, C) = (3, 5, 153, 2, 274277, -38)
        let J = value
        var f: Int = Int(J) + j + C
        f += (((4 * Int(J) + B) / 146097) * 3) / 4
        let e = r * f + v
        let g = (e % p) / r
        let h = u * g + w
        let day = (h % s) / u + 1
        let month = (h / s + m) % n + 1
        let year = e / p - y + (n + m - month) / n
        var frac = (modf(J).1 > 0.5 ? modf(J).1 - 0.5 : modf(J).1 + 0.5) * 86400
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
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        return dateComponents.date!
    }
}
