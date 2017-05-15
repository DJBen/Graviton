//
//  ObserverEphemerisParser.swift
//  Graviton
//
//  Created by Sihao Lu on 5/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

public final class ObserverRiseTransitSetParser: CommonParser, Parser {
    public typealias Result = [RiseTransitSetInfo]

    public static let `default` = ObserverRiseTransitSetParser()

    public func parse(content: String) -> [RiseTransitSetInfo] {
        let lines = content.components(separatedBy: "\n")
        let systemInfo = parseLineBasedContent(content)
        guard let naifId = extractNameId(systemInfo["Target body name"])?.1 else { fatalError() }
        guard let coord = extractCoordinate(systemInfo["Center geodetic"]) else { fatalError() }
        let soeIndex = lines.index(where: { $0.contains("$$SOE") })!
        let eoeIndex = lines.index(where: { $0.contains("$$EOE") })!
        return lines[(soeIndex + 1)..<eoeIndex].map { (line) -> RiseTransitSetInfo in
            let components = line.components(separatedBy: ",").map { $0.trimmed() }
            let jd = Double(components[0])!
            let daylightFlag = components[1]
            let rtsFlag = components[2]
            let azi = Double(components[3])!
            let elev = Double(components[4])!
            return RiseTransitSetInfo(naifId: naifId, jd: jd, location: coord, daylightFlag: daylightFlag, rtsFlag: rtsFlag, azimuth: azi, elevation: elev)
        }
    }
}
