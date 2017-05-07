//
//  ObserverEphemerisParser.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

public final class ObserverEphemerisParser: CommonParser, Parser {
    public typealias Result = [CelestialBodyObserverInfo]

    public static let `default` = ObserverEphemerisParser()

    public func parse(content: String) -> [CelestialBodyObserverInfo] {
        let lines = content.components(separatedBy: "\n")
        let systemInfo = parseLineBasedContent(content)
        guard let naifId = extractNameId(systemInfo["Target body name"])?.1 else { fatalError() }
        let soeIndex = lines.index(where: { $0.contains("$$SOE") })!
        let eoeIndex = lines.index(where: { $0.contains("$$EOE") })!
        let labels = lines[soeIndex - 2].components(separatedBy: ",").map { $0.trimmed() }

        func extractContent(of components: [String], for field: String) -> String {
            return components[labels.index(of: field)!]
        }

        return lines[(soeIndex + 1)..<eoeIndex].map { (line) -> CelestialBodyObserverInfo in
            let components = line.components(separatedBy: ",").map { $0.trimmed() }
            let jd = Double(components[0])!
            let daylightFlag = components[1]
            let rtsFlag = components[2]
            let result = CelestialBodyObserverInfo()
            result.naifId = naifId
            result.jd = jd
            result.daylightFlag = daylightFlag
            result.rtsFlag = rtsFlag
            result.apparentMagnitude = Double(extractContent(of: components, for: "APmag"))!
            result.angularDiameter = Double(extractContent(of: components, for: "Ang-diam"))!
            result.surfaceBrightness = Double(extractContent(of: components, for: "S-brt"))!
            result.illuminatedPercentage = Double(extractContent(of: components, for: "Illu%"))!
            result.obLon = Double(extractContent(of: components, for: "Obsrv-lon"))!
            result.obLat = Double(extractContent(of: components, for: "Obsrv-lat"))!
            result.slLon = Double(extractContent(of: components, for: "Solar-lon"))!
            result.slLat = Double(extractContent(of: components, for: "Solar-lat"))!
            result.npRa = Double(extractContent(of: components, for: "N.Pole-RA"))!
            result.npDec = Double(extractContent(of: components, for: "N.Pole-DC"))!
            return result
        }
    }
}
