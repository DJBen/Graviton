//
//  CelestialBodyObserverInfo.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import RealmSwift
import SpaceTime

public final class CelestialBodyObserverInfo: ObserverInfo {
    @objc public dynamic var rightAscension: Double = 0
    @objc public dynamic var declination: Double = 0

    public let apparentMagnitude = RealmOptional<Double>()
    public let surfaceBrightness = RealmOptional<Double>()

    /// Fraction of target circular disk illuminated by Sun (phase), as seen by observer.  Units: PERCENT
    @objc public dynamic var illuminatedPercentage: Double = 0

    /// The equatorial angular width of the target body full disk, if it were fully visible to the observer.  Units: ARCSECONDS
    @objc public dynamic var angularDiameter: Double = 0

    @objc public dynamic var obLon: Double = 0
    @objc public dynamic var obLat: Double = 0

    // Solar sub-longitude or sub-latitude will be nil for the Sun.
    public let slLon = RealmOptional<Double>()
    public let slLat = RealmOptional<Double>()

    @objc public dynamic var npAng: Double = 0
    @objc public dynamic var npDs: Double = 0

    @objc public dynamic var npRa: Double = 0
    @objc public dynamic var npDec: Double = 0
}

extension CelestialBodyObserverInfo: ObserverLoadable {
    static func load(naifId: Int, optimalJulianDay julianDay: JulianDay = JulianDay.now, site: ObserverSite, timeZone: TimeZone) -> CelestialBodyObserverInfo? {
        let realm = try! Realm()
        let jdStart = julianDay - 60 * 30
        let jdEnd = julianDay + 60 * 30
        let results = try! realm.objects(CelestialBodyObserverInfo.self).filter("naifId == %@ AND jd BETWEEN {%@, %@}", naifId, jdStart.value, jdEnd.value).filterGeoRadius(center: site.location.coordinate, radius: ObserverInfo.distanceTolerance, sortAscending: true)
        let info = Array(results)
        guard info.isEmpty == false else { return nil }
        return info.reduce(info[0]) { (r1, r2) -> CelestialBodyObserverInfo in
            abs(r1.julianDay - julianDay) > abs(r2.julianDay - julianDay) ? r2 : r1
        }
    }

    public static func clearOutdatedInfo(daysAgo days: Double = 7, sinceJulianDate julianDay: JulianDay = JulianDay.now) {
        do {
            let realm = try Realm()
            let results = realm.objects(CelestialBodyObserverInfo.self).filter("jd < %@", julianDay.value - days)
            try realm.write {
                realm.delete(results)
            }
            logger.info("\(results.count) outdated CelestialBodyObserverInfo objects cleared. Criteria: JD < \(julianDay.value - days)")
        } catch {
            logger.warning("Failed to clear outdated CelestialBodyObserverInfo objects. Criteria: JD < \(julianDay.value - days). Failure reason: \(error)")
        }
    }
}

extension Collection where Iterator.Element == CelestialBodyObserverInfo {
    func save() {
        let realm = try! Realm()
        try! realm.write {
            realm.add(self)
        }
    }
}
