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
        return "{ dynamics: { jd: \(julianDate!), position: \(position) } motion: { ref_jd: \(ephemerisJulianDate), toPP: \(timeOfPeriapsisPassage!) gm: \(gm), orbit: \(orbit) } }"
    }
    
    /// A referential julian date when the ephemeris is recorded
    public let ephemerisJulianDate: JulianDate
        
    public init(orbit: Orbit, gm: Double, julianDate: JulianDate, timeOfPeriapsisPassage: JulianDate) {
        self.ephemerisJulianDate = julianDate
        super.init(orbit: orbit, gm: gm, phase: .julianDate(julianDate))
        self.timeOfPeriapsisPassage = timeOfPeriapsisPassage
    }
    
    // MARK: - NSCopying
    public override func copy(with zone: NSZone? = nil) -> Any {
        return OrbitalMotionMoment.init(orbit: orbit, gm: gm, julianDate: julianDate!, timeOfPeriapsisPassage: timeOfPeriapsisPassage!)
    }
}
