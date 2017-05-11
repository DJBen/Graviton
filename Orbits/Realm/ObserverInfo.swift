//
//  ObserverInfo.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import RealmSwift
import SpaceTime

public class ObserverInfo: Object {
    public enum RiseTransitSet {
        case aboveHorizon
        case belowHorizon
        case rise
        case transit
        case set
    }

    public enum SolarPresence {
        case day
        case civilDawn
        case nauticalDawn
        case astronomicalDawn
        case night
    }

    dynamic var naifId: Int = 0
    dynamic var jd: Double = 0
    dynamic var rtsFlag: String = ""
    dynamic var daylightFlag: String = ""

    public var naif: Naif {
        return Naif(naifId: naifId)
    }

    public var rts: RiseTransitSet {
        switch rtsFlag {
        case "r":
            return .rise
        case "t":
            return .transit
        case "s":
            return .set
        case "m":
            return .aboveHorizon
        case "":
            return .belowHorizon
        default:
            fatalError()
        }
    }

    public var daylight: SolarPresence {
        let translation: [String: SolarPresence] = [
            "*": .day,
            "": .night,
            "C": .civilDawn,
            "N": .nauticalDawn,
            "A": .astronomicalDawn
        ]
        return translation[daylightFlag]!
    }

    public var julianDate: JulianDate {
        return JulianDate(jd)
    }

    override public static func indexedProperties() -> [String] {
        return ["naifId", "rtsFlag"]
    }
}
