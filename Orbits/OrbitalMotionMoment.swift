//
//  OrbitalMotionMoment.swift
//  Orbits
//
//  Created by Sihao Lu on 12/29/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime

public class OrbitalMotionMoment: OrbitalMotion {

    public override var description: String {
        return "{ dynamics: { jd: \(julianDay!), position: \(position) } motion: { ref_jd: \(ephemerisJulianDay), toPP: \(timeOfPeriapsisPassage!) gm: \(gm), orbit: \(orbit) } }"
    }

    /// A referential julian date when the ephemeris is recorded
    public let ephemerisJulianDay: JulianDay

    public init(orbit: Orbit, gm: Double, julianDay: JulianDay, timeOfPeriapsisPassage: JulianDay) {
        self.ephemerisJulianDay = julianDay
        super.init(orbit: orbit, gm: gm, phase: .julianDay(julianDay))
        self.timeOfPeriapsisPassage = timeOfPeriapsisPassage
    }

    // MARK: - NSCopying
    public override func copy(with zone: NSZone? = nil) -> Any {
        return OrbitalMotionMoment.init(orbit: orbit, gm: gm, julianDay: julianDay!, timeOfPeriapsisPassage: timeOfPeriapsisPassage!)
    }
}
