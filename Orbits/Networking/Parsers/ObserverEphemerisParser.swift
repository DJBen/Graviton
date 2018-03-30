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

    private enum Field {
        case rightAscension
        case declination
        case apparentMagnitude
        case angularDiameter
        case obLon
        case obLat
        case slLon
        case slLat
        case northPoleRa
        case northPoleDec
        case northPoleAng
        case northPoleDist
        case illuminatedPercentage
        case surfaceBrightness

        var strings: [String] {
            switch self {
            case .rightAscension:
                return ["R.A._(ICRF/J2000.0)"]
            case .declination:
                return ["DEC_(ICRF/J2000.0)"]
            case .apparentMagnitude:
                return ["APmag"]
            case .angularDiameter:
                return ["Ang-diam"]
            case .surfaceBrightness:
                return ["S-brt"]
            case .illuminatedPercentage:
                return ["Illu%"]
            case .obLat:
                return ["Obsrv-lat", "Ob-lat"]
            case .obLon:
                return ["Obsrv-lon", "Ob-lon"]
            case .slLat:
                return ["Solar-lat", "Sl-lat"]
            case .slLon:
                return ["Solar-lon", "Sl-lon"]
            case .northPoleRa:
                return ["N.Pole-RA"]
            case .northPoleDec:
                return ["N.Pole-DC"]
            case .northPoleAng:
                return ["NP.ang"]
            case .northPoleDist:
                return ["NP.dist"]
            }
        }
    }

    public func parse(content: String) -> [CelestialBodyObserverInfo] {
        let lines = content.components(separatedBy: "\n")
        let systemInfo = parseLineBasedContent(content)
        guard let naifId = extractNameId(systemInfo["Target body name"])?.1 else { fatalError() }
        guard let coord = extractCoordinate(systemInfo["Center geodetic"]) else { fatalError() }
        let soeIndex = lines.index(where: { $0.contains("$$SOE") })!
        let eoeIndex = lines.index(where: { $0.contains("$$EOE") })!
        let labels = lines[soeIndex - 2].components(separatedBy: ",").map { $0.trimmed() }

        func extractContent(of components: [String], for field: Field) -> String {
            let index = field.strings.compactMap { labels.index(of: $0) }.first!
            return components[index]
        }

        return lines[(soeIndex + 1)..<eoeIndex].map { (line) -> CelestialBodyObserverInfo in
            let components = line.components(separatedBy: ",").map { $0.trimmed() }
            let jd = Double(components[0])!
            let daylightFlag = components[1]
            let rtsFlag = components[2]
            let result = CelestialBodyObserverInfo()
            result.naifId = naifId
            result.jd = jd
            result.location = coord
            result.daylightFlag = daylightFlag
            result.rtsFlag = rtsFlag
            result.angularDiameter = Double(extractContent(of: components, for: .angularDiameter))!
            result.apparentMagnitude.value = Double(extractContent(of: components, for: .apparentMagnitude))
            result.surfaceBrightness.value = Double(extractContent(of: components, for: .surfaceBrightness))
            result.illuminatedPercentage = Double(extractContent(of: components, for: .illuminatedPercentage))!
            result.rightAscension = Double(extractContent(of: components, for: .rightAscension))!
            result.declination = Double(extractContent(of: components, for: .declination))!
            result.obLon = Double(extractContent(of: components, for: .obLon))!
            result.obLat = Double(extractContent(of: components, for: .obLat))!
            result.slLon.value = Double(extractContent(of: components, for: .slLon))
            result.slLat.value = Double(extractContent(of: components, for: .slLat))
            result.npRa = Double(extractContent(of: components, for: .northPoleRa))!
            result.npDec = Double(extractContent(of: components, for: .northPoleDec))!
            result.npAng = Double(extractContent(of: components, for: .northPoleAng))!
            result.npDs = Double(extractContent(of: components, for: .northPoleDist))!
            return result
        }
    }
}
