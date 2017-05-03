
//
//  HorizonsQuery.swift
//  Orbits
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

public struct HorizonsQuery: Hashable {
    public enum TableType: String {
        case elements
        case observer
        case vectors
        case approach
    }
    
    public enum StepSize: Equatable {
        case day(Int)
        case hour(Int)
        case minute(Int)
        case month(Int)
        case year(Int)
        case step(Int)
        
        var rawValue: String {
            switch self {
            case let .year(y):
                return "\(y)y"
            case let .month(mm):
                return "\(mm)month"
            case let .day(d):
                return "\(d)d"
            case let .hour(h):
                return "\(h)h"
            case let .minute(m):
                return "\(m)m"
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
    
    public var hashValue: Int {
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
    
    public init(naif: Naif, startTime: Date, stopTime: Date, stepSize: StepSize) {
        self.init(center: naif.primary?.rawValue, command: naif.rawValue, startTime: startTime, stopTime: stopTime, stepSize: stepSize)
    }
    
    init(center: Int?, command: Int, shouldMakeEphemeris: Bool = true, tableType: TableType = .elements, startTime: Date, stopTime: Date, useCsvFormat: Bool = true, stepSize: StepSize) {
        self.center = center
        self.command = command
        self.shouldMakeEphemeris = shouldMakeEphemeris
        self.tableType = tableType
        self.startTime = startTime
        self.stopTime = stopTime
        self.useCsvFormat = useCsvFormat
        self.stepSize = stepSize
    }
    
    public static func planetQuery(date: Date) -> [HorizonsQuery] {
        return ephemerisQuery([Naif.sun] + Naif.planets, date: date)
    }
    
    private static let numberOfMoonsInterested = [0, 0, 1, 2, 4, 5, 2, 2]
    public static let defaultQueryItems: [Naif] = [Naif.sun] + Naif.planets + zip(numberOfMoonsInterested, Naif.planets.prefix(8)).flatMap { $1.moons.prefix($0) }
    
    public static func defaultQuery(date: Date) -> [HorizonsQuery] {
        return ephemerisQuery(defaultQueryItems, date: date)
    }
    
    public static func ephemerisQuery(_ naifs: [Naif], date: Date) -> [HorizonsQuery] {
        // update yearly for planets
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.era, .year], from: date)
        let thisYear = calendar.date(from: components)!
        let thisYearLittleBitLater = thisYear.addingTimeInterval(1800)
        // update monthly for earth's moon (accuracy demands)
        let monthComponents = calendar.dateComponents([.era, .year, .month], from: date)
        let thisMonth = calendar.date(from: monthComponents)!
        let thisMonthLittleBitLater = thisMonth.addingTimeInterval(1800)
        
        return Array(Set<Naif>(naifs)).sorted().flatMap { (naif) -> HorizonsQuery? in
            switch naif {
            case .majorBody(let planet):
                return HorizonsQuery(center: Naif.sun.rawValue, command: planet.rawValue, shouldMakeEphemeris: true, tableType: .elements, startTime: thisYear, stopTime: thisYearLittleBitLater, useCsvFormat: true, stepSize: StepSize.step(1))
            case .moon(let moon):
                if moon.rawValue == 301 {
                    return HorizonsQuery(center: moon.primary.rawValue, command: moon.rawValue, shouldMakeEphemeris: true, tableType: .elements, startTime: thisMonth, stopTime: thisMonthLittleBitLater, useCsvFormat: true, stepSize: StepSize.step(1))
                } else {
                    return HorizonsQuery(center: moon.primary.rawValue, command: moon.rawValue, shouldMakeEphemeris: true, tableType: .elements, startTime: thisYear, stopTime: thisYearLittleBitLater, useCsvFormat: true, stepSize: StepSize.step(1))
                }
            default:
                return nil
            }
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
