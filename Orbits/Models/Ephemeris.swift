//
//  Ephemeris.swift
//  StarCatalog
//
//  Created by Ben Lu on 11/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation

public struct Ephemeris {
    // TODO: use hash map
    public let celestialBodies: [CelestialBody]
    
    public init(celestialBodies: [CelestialBody]) {
        self.celestialBodies = celestialBodies
    }
    
    public func motion(of naifId: Int) -> OrbitalMotion? {
        return self[naifId]?.motion
    }
    
    public func orbit(of naifId: Int) -> Orbit? {
        return motion(of: naifId)?.orbit
    }
    
    subscript(naifId: Int) -> CelestialBody? {
        return celestialBodies.filter { (body) -> Bool in
            return body.naifId == naifId
        }.first
    }
}
 
