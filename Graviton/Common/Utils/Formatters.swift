//
//  Formatters.swift
//  Graviton
//
//  Created by Sihao Lu on 7/15/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

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
            return localTimeDateFormatter
        }
    }
}
