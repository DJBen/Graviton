//
//  CommonParser.swift
//  Graviton
//
//  Created by Sihao Lu on 5/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import MathUtil
import CoreLocation

public class CommonParser {
    func parseLineBasedContent(_ content: String) -> [String: (String, String?)] {
        let physicalDataRegex = "Ephemeris[^\\*]+\\*+([^\\*]+)\\*+([^\\*]+)\\*+([^\\*]+)\\*+"
        let planetDataMatched = content.matches(for: physicalDataRegex)[0]
        let info = (1...3).map { planetDataMatched[$0] }.joined(separator: "\n").components(separatedBy: "\n")
        let regex = "^([^:]+):\\s([^\\{]+)(\\{[^\\}]+\\})?$"
        var results = [String: (String, String?)]()
        info.map { (i) -> [(String, String, String?)] in
            return i.matches(for: regex).flatMap { (matches) -> (String, String, String?)? in
                guard matches.count == 4 else { return nil }
                let m = matches.map { $0.trimmed() }
                return (m[1], m[2], m[3].isEmpty ? nil : m[3])
            }
            }.reduce([], +).forEach { results[$0] = ($1, $2) }
        return results
    }

    func extractCoordinate(_ coord: (String, String?)?) -> CLLocation? {
        guard let coord = coord else { return nil }
        let components = coord.0.components(separatedBy: ",").flatMap { Double($0.trimmed()) }
        guard components.count == 3 else { return nil }
        // TODO: calculate height regarding reference ellipsoid
        // https://en.wikipedia.org/wiki/Reference_ellipsoid
        return CLLocation(latitude: components[1], longitude: wrapLongitude(components[0]))
    }

    func extractNameId(_ nameId: (String, String?)?) -> (String, Int)? {
        guard let ni = nameId else { return nil }
        let matches = ni.0.matches(for: "(\\w+)\\s*\\((\\d+)\\)")
        guard matches.count > 0 else { return nil }
        guard matches[0].count > 2 else { return nil }
        return (matches[0][1], Int(matches[0][2])!)
    }
}

func dict<T: Hashable>(_ tuple: [(T, T)]) -> [T: T] {
    var map: [T: T] = [:]
    tuple.forEach { map[$0.0] = $0.1 }
    return map
}

func dropLast<T>(_ tuple: (T, T, T?)) -> (T, T) {
    return (tuple.0, tuple.1)
}

extension String {
    func matches(regex: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            return regex.numberOfMatches(in: self, options: [], range: NSRange(location: 0, length: nsString.length)) >= 1
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }

    func matches(for regex: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            guard results.count > 0 else {
                return []
            }
            return results.map { (result) -> [String] in
                return (0..<result.numberOfRanges).map { (index) -> String in
                    guard result.rangeAt(index).length > 0 else {
                        return String()
                    }
                    return (self as NSString).substring(with: result.rangeAt(index))
                }
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    func trimmed() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
