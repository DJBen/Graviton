//
//  RiseTransitSetElevation.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SpaceTime
import MathUtil
import RealmSwift

public struct RiseTransitSetElevation {

    /// Maximum elevation in radians
    public let maximumElevation: Double
    public let riseAt: JulianDate
    public let transitAt: JulianDate
    public let setAt: JulianDate

    init?(rts: [RiseTransitSetInfo]) {
        let r = rts.first { $0.rts == .rise }
        let t = rts.first { $0.rts == .transit }
        let s = rts.first { $0.rts == .set }
        if r == nil || t == nil || s == nil {
            return nil
        }
        maximumElevation = radians(degrees: t!.elevation)
        riseAt = r!.julianDate
        transitAt = t!.julianDate
        setAt = s!.julianDate
    }
}

public extension RiseTransitSetElevation {

    /// Load the rise-transit-set info that is on the requested Julian date.
    ///
    /// - Parameters:
    ///   - naifId: Naif ID of the target body
    ///   - julianDate: The requested Julian date
    ///   - timeZone: The time zone of user
    /// - Returns: A rise-transit-set info record within the same day of requested Julian date
    static func load(naifId: Int, optimalJulianDate julianDate: JulianDate = JulianDate.now(), timeZone: TimeZone = TimeZone.current) -> RiseTransitSetElevation? {
        let realm = try! Realm()
        let deltaT = Double(timeZone.secondsFromGMT()) / 86400
        let jdStart = modf(julianDate.value).0 + deltaT
        let jdEnd = modf(julianDate.value).0 + 1 + deltaT
        let results = realm.objects(RiseTransitSetInfo.self).filter("jd BETWEEN {%@, %@}", jdStart, jdEnd)
        return RiseTransitSetElevation(rts: Array(results))
    }
}
