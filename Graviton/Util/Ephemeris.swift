//
//  Ephemeris.swift
//  Graviton
//
//  Created by Ben Lu on 11/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import Orbits

public struct Ephemeris {
    public let julianDate: JulianDate
    // TODO: use hash map
    public let celestialBodies: [CelestialBody]
    
    public init(julianDate: JulianDate, celestialBodies: [CelestialBody]) {
        self.julianDate = julianDate
        self.celestialBodies = celestialBodies
    }
    
    public func orbit(of naifId: String) -> Orbit? {
        return celestialBodies.filter { (body) -> Bool in
            return body.name == naifId
        }.first?.motion?.orbit
    }
}
 
