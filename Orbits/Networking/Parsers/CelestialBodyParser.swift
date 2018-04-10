//
//  EphemerisParser.swift
//  StarCatalog
//
//  Created by Ben Lu on 10/4/16.
//
//

import Foundation
import MathUtil

public final class CelestialBodyParser: CommonParser, Parser {
    public typealias Result = CelestialBody?

    public static let `default` = CelestialBodyParser()

    // parse range 1
    func parseField(_ content: String) -> [String: String] {
        let lines = content.components(separatedBy: "\n")
        let noHead = lines.drop(while: { $0.matches(regex: "\\*\\*\\*") == false }).dropFirst()
        let remaining = noHead.prefix(while: { $0.matches(regex: "\\*\\*\\*") == false })
        var results = [String: String]()
        remaining.compactMap { (line) -> [(String, String)]? in
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

    public func parse(content: String) -> CelestialBody? {
        let bodyInfo = parseField(content)
        let systemInfo = parseLineBasedContent(content)
        guard let naifId = extractNameId(systemInfo["Target body name"])?.1 else { fatalError() }
        let extractor = PropertyExtractor.extractor(forNaif: naifId, bodyInfo: bodyInfo)
        guard let motion = EphemerisMotionParser.default.parse(content: content).first else { fatalError() }
        guard let radius = extractor.radius else { fatalError() }
        guard let centerId = extractNameId(systemInfo["Center body name"])?.1 else { fatalError() }
        guard let gm = extractor.gm else { fatalError() }
        let rotRate = extractor.rotationPeriod(naifId: naifId, orb: motion.orbitalPeriod!) ?? 0
        let hsRp = extractor.hillSphere
        // Consider Mercury to have 0 obliquity
        let obliquity = extractor.obliquity ?? DegreeAngle(0)
        let body = CelestialBody(naifId: naifId, gravParam: gm, radius: radius, rotationPeriod: rotRate, obliquity: obliquity, centerBodyNaifId: centerId, hillSphereRadRp: hsRp)
        body.motion = motion
        return body
    }
}
