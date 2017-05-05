//
//  EphemerisParser.swift
//  StarCatalog
//
//  Created by Ben Lu on 10/4/16.
//
//

import Foundation
import MathUtil

public struct ResponseParser: Parser {
    public typealias Result = CelestialBody?

    public static let `default` = ResponseParser()

    // parse range 1
    func parseField(_ content: String) -> [String: String] {
        let lines = content.components(separatedBy: "\n")
        let noHead = lines.drop(while: { $0.matches(regex: "\\*\\*\\*") == false }).dropFirst()
        let remaining = noHead.prefix(while: { $0.matches(regex: "\\*\\*\\*") == false })
        var results = [String: String]()
        remaining.flatMap { (line) -> [(String, String)]? in
            guard let result = parseDoubleColumn(line) else { return nil }
            if let col2 = result.1 {
                return [result.0, col2]
            } else {
                return [result.0]
            }
        }.reduce([], +).forEach { results[$0] = $1 }
        return results
    }

    // parse range 1 - subroutine
    func parseDoubleColumn(_ line: String) -> ((String, String), (String, String)?)? {
        let lineRegex = "^\\s*(?:(?:(.{38})\\s+)|(?:(.{38}\\S+)\\s+))(.+)$"
        let propertyRegex = "(.+)\\s*=\\s*(.{5,24}|[\\d.-]+)"
        let matched = line.matches(for: lineRegex)
        guard matched.count == 1 else {
            let singleProp = line.matches(for: propertyRegex)
            guard singleProp.isEmpty == false else { return nil }
            return ((singleProp[0][1], singleProp[0][2]), nil)
        }
        let m = matched[0]
        guard m.count == 4 else { return nil }

        func parseProperty(_ propLine: String) -> (String, String)? {
            let props = propLine.matches(for: propertyRegex)
            guard props.isEmpty == false else { return nil }
            let p = props[0]
            return (p[1].trimmed(), p[2].trimmed())
        }
        func twoProps() -> (String, String) {
            let first = m[1].isEmpty ? m[2] : m[1]
            return (first, m[3])
        }
        let tp = twoProps()
        if let firstProperty = parseProperty(tp.0) {
            return (firstProperty, parseProperty(tp.1))
        } else { return nil }
    }

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

    // MARK: - Small parsing functions

    func extractNameId(_ nameId: (String, String?)?) -> (String, Int)? {
        guard let ni = nameId else { return nil }
        let matches = ni.0.matches(for: "(\\w+)\\s*\\((\\d+)\\)")
        guard matches.count > 0 else { return nil }
        guard matches[0].count > 2 else { return nil }
        return (matches[0][1], Int(matches[0][2])!)
    }

    public func parse(content: String) -> CelestialBody? {
        let bodyInfo = parseField(content)
        let systemInfo = parseLineBasedContent(content)
        guard let naifId = extractNameId(systemInfo["Target body name"])?.1 else { fatalError() }
        let extractor = PropertyExtractor.extractor(forNaif: naifId, bodyInfo: bodyInfo)
        guard let motion = parseEphemeris(content: content).first else { fatalError() }
        guard let radius = extractor.radius else { fatalError() }
        guard let centerId = extractNameId(systemInfo["Center body name"])?.1 else { fatalError() }
        guard let gm = extractor.gm else { fatalError() }
        let rotRate = extractor.rotationPeriod(naifId: naifId, orb: motion.orbitalPeriod!) ?? 0
        let hsRp = extractor.hillSphere
        // TODO: parse mercury obliquity
        let obliquity = extractor.obliquity ?? 0
        let body = CelestialBody(naifId: naifId, gravParam: gm, radius: radius, rotationPeriod: rotRate, obliquity: obliquity, centerBodyNaifId: centerId, hillSphereRadRp: hsRp)
        body.motion = motion
        return body
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
