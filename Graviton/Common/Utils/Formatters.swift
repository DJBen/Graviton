//
//  Formatters.swift
//  Graviton
//
//  Created by Sihao Lu on 7/15/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import MathUtil
import UIKit

struct Formatters {
    private static let utcDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd hh:mm a 'UTC'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        return formatter
    }()

    private static let localTimeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd hh:mm a"
        return formatter
    }()

    static var dateFormatter: DateFormatter {
        if Settings.default[.useUtcTime] {
            return utcDateFormatter
        } else {
            localTimeDateFormatter.timeZone = LocationManager.default.timeZone
            return localTimeDateFormatter
        }
    }

    static let fullUtcDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        return formatter
    }()

    static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()

    static let twoDecimalPointFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let scientificNotationFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .scientific
        numberFormatter.maximumSignificantDigits = 4
        return numberFormatter
    }()

    static let julianDayFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 5
        return formatter
    }()
}

class CoordinateFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let coordinate = obj as? CLLocationCoordinate2D else {
            return nil
        }
        let lat = coordinate.latitude
        let long = coordinate.longitude
        func stripNegativeSign(_ dms: DegreeAngle) -> String {
            if dms.value >= 0 {
                return dms.compoundDescription
            } else {
                var str = dms.compoundDescription
                str.remove(at: str.startIndex)
                return str
            }
        }
        let latDms = DegreeAngle(lat)
        latDms.wrapMode = .range_180
        latDms.compoundDecimalNumberFormatter = Formatters.twoDecimalPointFormatter
        let longDms = DegreeAngle(long)
        longDms.wrapMode = .range_180
        longDms.compoundDecimalNumberFormatter = Formatters.twoDecimalPointFormatter
        let latStr = stripNegativeSign(latDms) + (lat >= 0 ? " N" : " S")
        let longStr = stripNegativeSign(longDms) + (long >= 0 ? " E" : " W")
        return "\(latStr), \(longStr)"
    }
}
