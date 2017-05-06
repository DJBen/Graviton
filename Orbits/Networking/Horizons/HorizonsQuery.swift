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
import CoreLocation

public struct HorizonsQuery: Hashable {

    public enum TableType: String {
        case elements
        case observer
        case vectors
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

    public enum RTSMode: String {
        case none = "NO"
        case trueVisualHorizon = "TVH"
        case geometricHorizon = "GEO"
        case radarHorizon = "RAD"
    }

    public enum RangeUnit: String {
        case AU
        case km
    }

    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MMM-dd HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    public var hashValue: Int {
        return command.hashValue ^ startTime.hashValue ^ stopTime.hashValue ^ stepSize.rawValue.hashValue
    }

    let tableType: TableType
    var center: String
    let command: Int
    var shouldMakeEphemeris: Bool = true
    var startTime: Date
    var stopTime: Date
    var showObjectPage: Bool = true
    var useCsvFormat: Bool = true
    var stepSize: StepSize = .step(1)

    var observerField: ObserverField = .geocentricObserverFields
    var site: CLLocation = CLLocation()
    var rtsMode: RTSMode = .none
    var rangeUnit: RangeUnit = .km

    var queryItems: [URLQueryItem] {
        switch tableType {
        case .elements:
            return [
                "batch": "1",
                "MAKE_EPHEM": shouldMakeEphemeris.yesNo,
                "TABLE_TYPE": tableType.rawValue.capitalized,
                "COMMAND": String(command),
                "START_TIME": HorizonsQuery.formatter.string(from: startTime),
                "STOP_TIME": HorizonsQuery.formatter.string(from: stopTime),
                "CSV_FORMAT": useCsvFormat.yesNo,
                "STEP_SIZE": stepSize.rawValue,
                "CENTER": center
            ].keyOrderMap { (key, value) -> URLQueryItem in
                return URLQueryItem(name: key, value: value.quoteWrapped)
            }
        case .observer:
            return [
                "batch": "1",
                "TABLE_TYPE": tableType.rawValue.capitalized,
                "COMMAND": String(command),
                "QUANTITIES": observerField.quantities,
                "START_TIME": HorizonsQuery.formatter.string(from: startTime),
                "STOP_TIME": HorizonsQuery.formatter.string(from: stopTime),
                "CSV_FORMAT": useCsvFormat.yesNo,
                "R_T_S_ONLY": rtsMode.rawValue,
                "SITE_COORD": formatSite(site),
                "ANG_FORMAT": "DEG",
                "STEP_SIZE": stepSize.rawValue,
                "REF_SYSTEM": "J2000",
                "OBJ_PAGE": showObjectPage.yesNo,
                "CENTER": center
            ].keyOrderMap { (key, value) -> URLQueryItem in
                return URLQueryItem(name: key, value: value.quoteWrapped)
            }
        default:
            break
        }
        return []
    }

    var url: URL {
        let urlComponent = NSURLComponents(string: Horizons.batchUrl)!
        urlComponent.queryItems = queryItems
        return urlComponent.url!
    }

    public static func orbitalElementQuery(naif: Naif, startTime: Date, stopTime: Date) -> HorizonsQuery {
        return HorizonsQuery(naif: naif, tableType: .elements, startTime: startTime, stopTime: stopTime)
    }

    public static func observerQuery(target: Naif, site: ObserverSite, startTime: Date, stopTime: Date) -> HorizonsQuery {
        var query = HorizonsQuery(naif: target, tableType: .observer, startTime: startTime, stopTime: stopTime)
        query.site = site.location
        query.center = "coord@" + String(site.naif.rawValue)
        return query
    }

    public static func observerRtsQuery(target: Naif, site: ObserverSite, startTime: Date, stopTime: Date) -> HorizonsQuery {
        var query = HorizonsQuery(naif: target, tableType: .observer, startTime: startTime, stopTime: stopTime)
        query.site = site.location
        query.rtsMode = .trueVisualHorizon
        query.showObjectPage = false
        query.observerField = [.astrometricRaAndDec]
        query.center = "coord@" + String(site.naif.rawValue)
        return query
    }

    public static func planetQuery(date: Date) -> [HorizonsQuery] {
        return ephemerisQuery([Naif.sun] + Naif.planets, date: date)
    }

    public static let planetAndMoonQueryItems: [Naif] = [Naif.sun] + Naif.planets + zip([0, 0, 1, 2, 4, 5, 2, 2], Naif.planets.prefix(8)).flatMap { $1.moons.prefix($0) }

    public static func planetAndMoonQuery(date: Date) -> [HorizonsQuery] {
        return ephemerisQuery(planetAndMoonQueryItems, date: date)
    }

    public static func ephemerisQuery(_ naifs: [Naif], date: Date) -> [HorizonsQuery] {
        // update yearly for planets
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
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
                return HorizonsQuery(center: String(Naif.sun.rawValue), command: planet.rawValue, tableType: .elements, startTime: thisYear, stopTime: thisYearLittleBitLater)
            case .moon(let moon):
                if moon.rawValue == Naif.Moon.luna.rawValue {
                    return HorizonsQuery(center: String(moon.primary.rawValue), command: moon.rawValue, tableType: .elements, startTime: thisMonth, stopTime: thisMonthLittleBitLater)
                } else {
                    return HorizonsQuery(center: String(moon.primary.rawValue), command: moon.rawValue, tableType: .elements, startTime: thisYear, stopTime: thisYearLittleBitLater)
                }
            default:
                return nil
            }
        }
    }

    public static func rtsQueries(site: ObserverSite, date: Date) -> [HorizonsQuery] {
        var rtsInterested: Set<Naif> = Set<Naif>([Naif.moon(.luna)])
        rtsInterested.remove(site.naif)
        let weekLaterDate = date.addingTimeInterval(86400 * 7)
        return rtsInterested.map { target -> HorizonsQuery in
            var query = HorizonsQuery.observerQuery(target: target, site: site, startTime: date, stopTime: weekLaterDate)
            query.stepSize = .minute(1)
            query.observerField = [.astrometricRaAndDec]
            query.showObjectPage = false
            return query
        }
    }

    public static func observerQueries(site: ObserverSite, date: Date) -> [HorizonsQuery] {
        var interested: Set<Naif> = Set<Naif>([Naif.moon(.luna)])
        interested.remove(site.naif)
        let dayAhead = date.addingTimeInterval(86400)
        return interested.map { target -> HorizonsQuery in
            var query = HorizonsQuery.observerQuery(target: target, site: site, startTime: date, stopTime: dayAhead)
            query.stepSize = .minute(10)
            return query
        }
    }

    private init(naif: Naif, tableType: TableType, startTime: Date, stopTime: Date) {
        self.init(center: String(naif.primary!.rawValue), command: naif.rawValue, tableType: tableType, startTime: startTime, stopTime: stopTime)
    }

    private init(center: String, command: Int, tableType: TableType, startTime: Date, stopTime: Date) {
        self.center = center
        self.command = command
        self.tableType = tableType
        self.startTime = startTime
        self.stopTime = stopTime
    }

    // MARK: - Equatable
    public static func ==(lhs: HorizonsQuery, rhs: HorizonsQuery) -> Bool {
        return lhs.command == rhs.command && lhs.startTime == rhs.startTime && lhs.stopTime == rhs.stopTime && lhs.useCsvFormat == rhs.useCsvFormat && lhs.center == rhs.center && lhs.shouldMakeEphemeris == rhs.shouldMakeEphemeris && lhs.stepSize == rhs.stepSize && lhs.tableType == rhs.tableType
    }
}

fileprivate func formatSite(_ site: CLLocation) -> String {
    return "\(site.coordinate.longitude),\(site.coordinate.latitude),\(site.altitude)"
}

fileprivate extension Bool {
    var yesNo: String {
        return self ? "YES" : "NO"
    }
}

fileprivate extension String {
    var isQuoteWrapped: Bool {
        return self[startIndex] == "'" && self[index(before: endIndex)] == "'"
    }

    var quoteWrapped: String {
        if isQuoteWrapped { return self }
        return "'\(self)'"
    }
}
