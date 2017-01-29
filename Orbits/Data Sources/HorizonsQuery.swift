
//
//  HorizonsQuery.swift
//  Graviton
//
//  Created by Ben Lu on 1/27/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

// CENTER = 'SUN'
// COMMAND = '399'
// MAKE_EPHEM = 'YES'
// TABLE_TYPE = 'elements'
// START_TIME = '2000-10-01'
// STOP_TIME = '2000-12-31'
// STEP_SIZE = '15d'
// CSV_FORMAT = 'YES'

import Foundation

struct HorizonsQuery: Hashable {
    enum TableType: String {
        case elements
        case observers
        case vectors
        case approach
    }
    
    enum StepSize: Equatable {
        case day(Int)
        case hour(Int)
        case minute(Int)
        case step(Int)
        
        var rawValue: String {
            switch self {
            case let .day(d):
                return "\(d) days"
            case let .hour(h):
                return "\(h) hours"
            case let .minute(m):
                return "\(m) min"
            case let .step(s):
                return "\(s)"
            }
        }
        
        public static func ==(lhs: StepSize, rhs: StepSize) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
    
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MMM-dd HH:mm"
        return formatter
    }()
    
    var hashValue: Int {
        return command.hashValue ^ startTime.hashValue ^ stopTime.hashValue ^ stepSize.rawValue.hashValue
    }
    
    var center: Int?
    var command: Int
    var shouldMakeEphemeris: Bool = true
    var tableType: TableType
    var startTime: Date
    var stopTime: Date
    var useCsvFormat: Bool = true
    var stepSize: StepSize = .step(1)
    
    var queryItems: [URLQueryItem] {
        var mappings: [String: String] = [
            "batch": "1",
            "MAKE_EPHEM": shouldMakeEphemeris.yesNo,
            "TABLE_TYPE": tableType.rawValue.capitalized,
            "COMMAND": String(command),
            "START_TIME": HorizonsQuery.formatter.string(from: startTime),
            "STOP_TIME": HorizonsQuery.formatter.string(from: stopTime),
            "CSV_FORMAT": useCsvFormat.yesNo,
            "STEP_SIZE": stepSize.rawValue
        ]
        if let c = center {
            mappings["CENTER"] = String(c)
        }
        return mappings.map { (key, value) -> URLQueryItem in
            return URLQueryItem(name: key, value: value.quoteWrapped)
        }
    }
    
    var url: URL {
        let urlComponent = NSURLComponents(string: Horizons.batchUrl)!
        urlComponent.queryItems = queryItems
        return urlComponent.url!
    }
    
    static let planetQueryItems: [HorizonsQuery] = {
        return planetQuery(date: Date())
    }()
    
    public static func planetQuery(date: Date) -> [HorizonsQuery] {
        // update yearly for planets
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.era, .year], from: date)
        let thisYear = calendar.date(from: components)!
        let thisYearLittleBitLater = thisYear.addingTimeInterval(1800)
        return Naif.planets.map { (planet) -> HorizonsQuery in
            return HorizonsQuery(center: Naif.sun.rawValue, command: planet.rawValue, shouldMakeEphemeris: true, tableType: .elements, startTime: thisYear, stopTime: thisYearLittleBitLater, useCsvFormat: true, stepSize: StepSize.step(1))
        }
    }
    
    public static func ==(lhs: HorizonsQuery, rhs: HorizonsQuery) -> Bool {
        return lhs.command == rhs.command && lhs.startTime == rhs.startTime && lhs.stopTime == rhs.stopTime && lhs.useCsvFormat == rhs.useCsvFormat && lhs.center == rhs.center && lhs.shouldMakeEphemeris == rhs.shouldMakeEphemeris && lhs.stepSize == rhs.stepSize && lhs.tableType == rhs.tableType
    }
}

fileprivate extension Bool {
    var yesNo: String {
        return self ? "YES" : "NO"
    }
}

fileprivate extension String {
    var quoteWrapped: String {
        return "'\(self)'"
    }
}
