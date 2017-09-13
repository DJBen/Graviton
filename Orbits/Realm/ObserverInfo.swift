//
//  ObserverInfo.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import RealmSwift
import SpaceTime
import CoreLocation

public class ObserverInfo: Object {
    /// Distance tolerance in meters:
    /// records within radius will be regarded
    /// as referring to the same place.
    static let distanceTolerance: Double = 1000

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

    public dynamic var naifId: Int = 0
    public dynamic var jd: Double = 0
    // named "lat", "lng" to conform to default GeoQueries values
    public dynamic var lat: Double = 0
    public dynamic var lng: Double = 0
    public dynamic var altitude: Double = 0
    dynamic var rtsFlag: String = ""
    dynamic var daylightFlag: String = ""

    public var location: CLLocation {
        get {
            return CLLocation(coordinate: CLLocationCoordinate2D.init(latitude: lat, longitude: lng), altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
        }
        set {
            lat = newValue.coordinate.latitude
            lng = newValue.coordinate.longitude
            altitude = newValue.altitude
        }
    }

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

    override public static func ignoredProperties() -> [String] {
        return ["location"]
    }
}
