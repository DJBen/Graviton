//
//  EphemerisParser.swift
//  StarCatalog
//
//  Created by Ben Lu on 10/4/16.
//
//

import Foundation
import MathUtil

public struct ResponseValidator {
    public enum Result {
        case ok(String)
        case busy
    }
    
    public static func parse(content: String) -> Result {
        if content.contains("Blocked Concurrent Request") {
            return .busy
        } else {
            return .ok(content)
        }
    }
}

public struct ResponseParser {
    // parse range 1
    static func parseBodyInfo(_ content: String) -> [String: String] {
        let physicalDataRegex = "^\\*\\*+((?!\\*\\*)([\\s\\S]))+\\*\\*+"
        let planetDataMatched = content.matches(for: physicalDataRegex)[0]
        let info = planetDataMatched[0]
        var results = [String: String]()
        info.components(separatedBy: "\n").flatMap { (line) -> [(String, String)]? in
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
    static func parseDoubleColumn(_ line: String) -> ((String, String), (String, String)?)? {
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
    
    static func parseLineBasedContent(_ content: String) -> [String: (String, String?)] {
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
    
    public static func parseEphemeris(content: String) -> OrbitalMotion? {
        let ephemerisRegex = "\\$\\$SOE\\s*(([^,]*,\\s*)*)\\s*\\$\\$EOE"
        let matched = content.matches(for: ephemerisRegex)[0][1]
        return EphemerisParser.parse(csv: matched)
    }
    
    private enum BodyInfo {
        case hillSphere
        case rotationPeriod
        case obliquity
        case radius
        case gravParam
    }
    
    public static func parse(content: String) -> CelestialBody? {
        func kmToM(_ km: String?) -> Double? {
            if km == nil { return nil }
            if let matches = km?.matches(for: "([-\\d.]+)(?:(?:\\([\\+-\\.\\d]*\\))|(?:\\+-[\\d\\.]+))") {
                guard matches.count > 0 else { return nil }
                guard matches[0].count > 1 else { return nil }
                return Double(matches[0][1])! * 1000
            }
            return nil
        }
        func degToRadian(_ deg: String?) -> Double? {
            if deg == nil { return nil }
            if let matches = deg?.matches(for: "([-\\d.]+)\\s*(?:deg)?") {
                guard matches.count > 0 else { return nil }
                guard matches[0].count > 1 else { return nil }
                return radians(degrees: Double(matches[0][1])!)
            }
            return nil
        }
        func nameId(_ nameId: (String, String?)?) -> (String, Int)? {
            guard let ni = nameId else { return nil }
            let matches = ni.0.matches(for: "(\\w+)\\s*\\((\\d+)\\)")
            guard matches.count > 0 else { return nil }
            guard matches[0].count > 2 else { return nil }
            return (matches[0][1], Int(matches[0][2])!)
        }
        func rotPeriod(_ str: String?) -> Double? {
            if str == nil { return nil }
            if let matches = str?.matches(for: "([-\\d.]+)(\\+-[-\\d.]+)?\\s*(hr|d)?") {
                guard matches.count > 0 else { return nil }
                guard matches[0].count > 3 else { return nil }
                guard let result = Double(matches[0][1]) else { return nil }
                if matches[0][3] == "hr" || matches[0][3].isEmpty {
                    return result * 3600
                } else if matches[0][3] == "d" {
                    return result * 24 * 3600
                } else {
                    return nil
                }
            }
            return nil
        }
        func getGm(_ dict: [String: String]) -> Double? {
            let regex = "GM(?:,| \\()(10\\^(\\d+))?\\s*(km\\^3 s\\^-2|km\\^3\\/s\\^2)\\)?"
            // match 2 - exponent or nil (1)
            var exponent: Double = 0
            let gmKeys = dict.keys.filter { (key) -> Bool in
                let matches = key.matches(for: regex)
                return matches.isEmpty == false
            }
            guard let gmKey = gmKeys.first else { return nil }
            let matches = gmKey.matches(for: regex)
            if matches[0][2].lengthOfBytes(using: .utf8) > 0 {
                exponent = Double(matches[0][2])!
            }
            if let str = dict[gmKey], let result = Double(str.replacingOccurrences(of: ",", with: "")) {
                return result * pow(10, exponent)
            } else {
                return nil
            }
        }
        let bodyInfo = parseBodyInfo(content)
        func info(_ i: BodyInfo) -> String? {
            switch i {
            case .hillSphere:
                return bodyInfo["Hill's sphere rad. Rp"] ?? bodyInfo["Hill's sphere radius"] ?? bodyInfo["Hill's sphere rad., Rp"]
            case .rotationPeriod:
                return bodyInfo["Sidereal rot. period"] ?? bodyInfo["Sidereal period, hr"] ?? bodyInfo["Inferred rot. period"]
            case .obliquity:
                return bodyInfo["Obliquity to orbit"] ?? bodyInfo["Obliquity to orbit, deg"]
            case .radius:
                return bodyInfo["Mean radius (km)"] ?? bodyInfo["Mean radius, km"] ?? bodyInfo["Volumetric mean radius"]
            default:
                return nil
            }
        }
        let systemInfo = parseLineBasedContent(content)
        if let motion = parseEphemeris(content: content), let radius = kmToM(info(.radius)), let hillSphereRpStr = info(.hillSphere), let hsRp = Double(hillSphereRpStr), let naifId = nameId(systemInfo["Target body name"])?.1, let centerId = nameId(systemInfo["Center body name"])?.1, let gm = getGm(bodyInfo), let rotRate = rotPeriod(info(.rotationPeriod)) {
            // TODO: parse mercury obliquity
            let obliquity = degToRadian(info(.obliquity)) ?? 0
            let body = CelestialBody(naifId: naifId, gravParam: gm, radius: radius, rotationPeriod: rotRate, obliquity: obliquity, centerBodyNaifId: centerId, hillSphereRadRp: hsRp)
            body.motion = motion
            return body
        }
        return nil
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

fileprivate extension String {
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
