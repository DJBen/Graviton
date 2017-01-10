//
//  OrbitalMotionMoment.swift
//  Orbits
//
//  Created by Sihao Lu on 12/29/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit

public class OrbitalMotionMoment: OrbitalMotion {
    public let ephemerisJulianDate: Double
    
    public init(centralBody: CelestialBody, orbit: Orbit, julianDate: Double, timeOfPeriapsisPassage: Double) {
        self.ephemerisJulianDate = julianDate
        super.init(centralBody: centralBody, orbit: orbit, phase: .julianDate(julianDate))
        self.timeOfPeriapsisPassage = timeOfPeriapsisPassage
    }
}
