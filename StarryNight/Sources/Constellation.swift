//
//  Constellation.swift
//  Orbits
//
//  Created by Ben Lu on 2/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SQLite

public struct Constellation: Hashable {
    public struct Line: CustomStringConvertible {
        public let star1: Star
        public let star2: Star

        public var description: String {
            return "(\(star1) - \(star2))"
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(iAUName)
    }

    public static func ==(lhs: Constellation, rhs: Constellation) -> Bool {
        return lhs.iAUName == rhs.iAUName
    }

    private static var lineMappings: [String: [(Int, Int)]] = {
        let content = try! String(contentsOfFile: StarryNight.Constellations.constellationLinePath)
        let lines = content.components(separatedBy: "\n").filter { (str) -> Bool in
            return str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty == false
        }
        var dict: [String: [(Int, Int)]] = [:]
        lines.forEach { (line) in
            let lineComponents: [String] = line.components(separatedBy: " ").filter { $0.isEmpty == false }
            let con = lineComponents[0]
            var starHrs: [(Int, Int)] = []
            for (hr1, hr2) in zip(lineComponents[2..<(lineComponents.endIndex - 1)], lineComponents[3..<(lineComponents.endIndex)]) {
                starHrs.append((Int(hr1)!, Int(hr2)!))
            }
            if let connections = dict[con] {
                dict[con] = connections + starHrs
            } else {
                dict[con] = starHrs
            }
        }
        return dict
    }()

    public static var all: Set<Constellation> {
        do {
            var constellations = Set<Constellation>()
            for row in try StarryNight.db.prepare(StarryNight.Constellations.table) {
                let iau = try row.get(StarryNight.Constellations.dbIAUName)
                let con = Constellation(
                    name: try row.get(StarryNight.Constellations.dbName),
                    iAUName: iau,
                    genitive: try row.get(StarryNight.Constellations.dbGenitive)
                )
                constellations.insert(con)
            }
            return constellations
        } catch {
            return []
        }
    }

    private var lines: [(Int, Int)] {
        return Constellation.lineMappings[iAUName] ?? []
    }

    public let name: String
    public let iAUName: String
    public let genitive: String

    private init(name: String, iAUName: String, genitive: String) {
        self.name = name
        self.iAUName = iAUName
        self.genitive = genitive
    }

    public var connectionLines: [Line] {
        return lines.compactMap { (s1, s2) -> Line? in
            guard let star1 = Star.hr(s1), let star2 = Star.hr(s2) else {
                return nil
            }
            return Line(star1: star1, star2: star2)
        }
    }

    private static func queryConstellation(_ query: Table) -> Constellation? {
        do {
            if let row = try StarryNight.db.pluck(query) {
                return Constellation(
                    name: try row.get(StarryNight.Constellations.dbName),
                    iAUName: try row.get(StarryNight.Constellations.dbIAUName),
                    genitive: try row.get(StarryNight.Constellations.dbGenitive)
                )
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    public static func named(_ name: String) -> Constellation? {
        let query = StarryNight.Constellations.table.select(
            StarryNight.Constellations.dbName,
            StarryNight.Constellations.dbIAUName,
            StarryNight.Constellations.dbGenitive
        ).filter(StarryNight.Constellations.dbName == name)
        return queryConstellation(query)
    }

    public static func iau(_ iau: String) -> Constellation? {
        let query = StarryNight.Constellations.table.select(
            StarryNight.Constellations.dbName,
            StarryNight.Constellations.dbIAUName,
            StarryNight.Constellations.dbGenitive
        ).filter(StarryNight.Constellations.dbIAUName == iau)
        return queryConstellation(query)
    }
}
