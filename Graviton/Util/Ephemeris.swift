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
    // TODO: use hash map
    public let celestialBodies: [CelestialBody]
    
    public init(celestialBodies: [CelestialBody]) {
        self.celestialBodies = celestialBodies
    }
    
    public func motion(of naifId: String) -> OrbitalMotion? {
        return celestialBodies.filter { (body) -> Bool in
            return body.name == naifId
        }.first?.motion
    }
    
    public func orbit(of naifId: String) -> Orbit? {
        return motion(of: naifId)?.orbit
    }
}
 
