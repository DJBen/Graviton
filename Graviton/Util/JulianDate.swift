//
//  JulianDate.swift
//  Graviton
//
//  Created by Ben Lu on 11/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

public struct JulianDate {
    public let J1950: Double = 2433282.4235
    public let J2000: Double = 2451545.0
    
    let value: Double
    
    init(value: Double) {
        self.value = value
    }
    
    init(date: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
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
    
}
