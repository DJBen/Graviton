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

    @objc public dynamic var apparentMagnitude: Double = 0
    @objc public dynamic var surfaceBrightness: Double = 0

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
    static func load(naifId: Int, optimalJulianDate julianDate: JulianDate = JulianDate.now, site: ObserverSite, timeZone: TimeZone) -> CelestialBodyObserverInfo? {
        let realm = try! Realm()
        let jdStart = julianDate - 60 * 30
        let jdEnd = julianDate + 60 * 30
        let results = try! realm.objects(CelestialBodyObserverInfo.self).filter("naifId == %@ AND jd BETWEEN {%@, %@}", naifId, jdStart.value, jdEnd.value).filterGeoRadius(center: site.location.coordinate, radius: ObserverInfo.distanceTolerance, sortAscending: true)
        let info = Array(results)
        guard info.isEmpty == false else { return nil }
        return info.reduce(info[0]) { (r1, r2) -> CelestialBodyObserverInfo in
            abs(r1.julianDate - julianDate) > abs(r2.julianDate - julianDate) ? r2 : r1
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
