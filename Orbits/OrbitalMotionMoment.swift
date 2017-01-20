//
//  OrbitalMotionMoment.swift
//  Orbits
//
//  Created by Sihao Lu on 12/29/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

public class OrbitalMotionMoment: OrbitalMotion {
    
    /// A referential julian date when the ephemeris is recorded
    public let ephemerisJulianDate: Double
    
    public init(orbit: Orbit, gm: Double, julianDate: Double, timeOfPeriapsisPassage: Double) {
        self.ephemerisJulianDate = julianDate
        super.init(orbit: orbit, gm: gm, phase: .julianDate(julianDate))
        self.timeOfPeriapsisPassage = timeOfPeriapsisPassage
    }
}
