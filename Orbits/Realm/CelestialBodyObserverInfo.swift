//
//  CelestialBodyObserverInfo.swift
//  Graviton
//
//  Created by Sihao Lu on 5/7/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import RealmSwift
import SpaceTime

public class CelestialBodyObserverInfo: ObserverInfo {
    dynamic var apparentMagnitude: Double = 0
    dynamic var surfaceBrightness: Double = 0

    /// Fraction of target circular disk illuminated by Sun (phase), as seen by observer.  Units: PERCENT
    dynamic var illuminatedPercentage: Double = 0

    /// The equatorial angular width of the target body full disk, if it were fully visible to the observer.  Units: ARCSECONDS
    dynamic var angularDiameter: Double = 0

    dynamic var obLon: Double = 0
    dynamic var obLat: Double = 0

    dynamic var slLon: Double = 0
    dynamic var slLat: Double = 0

    dynamic var npRa: Double = 0
    dynamic var npDec: Double = 0
}
