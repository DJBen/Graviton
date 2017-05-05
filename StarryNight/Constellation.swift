//
//  Constellation.swift
//  Orbits
//
//  Created by Ben Lu on 2/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SQLite
import SpaceTime
import MathUtil

fileprivate let db = try! Connection(Bundle(identifier: "com.Square.sihao.StarryNight")!.path(forResource: "stars", ofType: "sqlite3")!)
fileprivate let constel = Table("constellations")
fileprivate let dbName = Expression<String>("constellation")
fileprivate let dbIAUName = Expression<String>("iau")
fileprivate let dbGenitive = Expression<String>("genitive")
fileprivate let constellationLinePath = Bundle(identifier: "com.Square.sihao.StarryNight")!.path(forResource: "constellation_lines", ofType: "dat")!

public struct Constellation: Hashable {
    public struct Line: CustomStringConvertible {
        public let star1: Star
        public let star2: Star

        public var description: String {
            return "(\(star1) - \(star2))"
        }
    }

    public var hashValue: Int {
        return iAUName.hashValue
    }

    public static func ==(lhs: Constellation, rhs: Constellation) -> Bool {
        return lhs.iAUName == rhs.iAUName
    }

    // IAU name -> constellation object
    private static var cachedConstellations = [String: Constellation]()

    private static var lineMappings: [String: [(Int, Int)]] = {
        let content = try! String(contentsOfFile: constellationLinePath)
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
        for row in try! db.prepare(constel) {
            let iau = row.get(dbIAUName)
            let con = Constellation(name: row.get(dbName), iAUName: iau, genitive: row.get(dbGenitive))
            if cachedConstellations[iau] == nil {
                cachedConstellations[iau] = con
            }
        }
        return Set<Constellation>(cachedConstellations.values)
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
        return lines.flatMap { (s1, s2) -> Line? in
            guard let star1 = Star.hr(s1), let star2 = Star.hr(s2) else {
                print("constellation \(name): line \(s1) - \(s2) not found")
                return nil
            }
            return Line(star1: star1, star2: star2)
        }
    }

    private static func queryConstellation(_ query: Table) -> Constellation? {
        if let row = try! db.pluck(query) {
            let con = Constellation(name: row.get(dbName), iAUName: row.get(dbIAUName), genitive: row.get(dbGenitive))
            cachedConstellations[row.get(dbIAUName)] = con
            return con
        }
        return nil
    }

    public static func named(_ name: String) -> Constellation? {
        if let conIndex: DictionaryIndex<String, Constellation> = cachedConstellations.index(where: { $1.name == name }) {
            let (_, v) = cachedConstellations[conIndex]
            return v
        }
        let query = constel.select(dbName, dbIAUName, dbGenitive).filter(dbName == name)
        return queryConstellation(query)
    }

    public static func iau(_ iau: String) -> Constellation? {
        if let con = cachedConstellations[iau] {
            return con
        }
        let query = constel.select(dbName, dbIAUName, dbGenitive).filter(dbIAUName == iau)
        return queryConstellation(query)
    }
}
