//
//  Formatters.swift
//  Graviton
//
//  Created by Sihao Lu on 7/15/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import CoreLocation
import MathUtil

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
            return localTimeDateFormatter
        }
    }

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
}

class CoordinateFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let coordinate = obj as? CLLocationCoordinate2D else {
            return nil
        }
        let lat = coordinate.latitude
        let long = coordinate.longitude
        func stripNegativeSign(_ dms: DegreeMinuteSecond) -> String {
            if dms.value >= 0 {
                return dms.description
            } else {
                var str = dms.description
                str.remove(at: str.startIndex)
                return str
            }
        }
        let latDms = DegreeMinuteSecond(value: lat)
        latDms.decimalNumberFormatter = Formatters.twoDecimalPointFormatter
        let longDms = DegreeMinuteSecond(value: long)
        longDms.decimalNumberFormatter = Formatters.twoDecimalPointFormatter
        let latStr = stripNegativeSign(latDms) + (lat >= 0 ? " N" : " S")
        let longStr = stripNegativeSign(longDms) + (long >= 0 ? " E" : " W")
        return "\(latStr), \(longStr)"
    }
}
