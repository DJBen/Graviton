//
//  SolarSystem.swift
//  Graviton
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import SpaceTime

protocol AstrodynamicsSupport {
    var body: Body { get }
}

struct SolarSystem: Searchable {
    let star: Sun
    var julianDate: Float = Float(JulianDate.J2000) {
        didSet {
            star.julianDate = julianDate
            star.satellites.forEach { $0.julianDate = self.julianDate }
        }
    }
    
    init(star: Sun) {
        self.star = star
    }
    
    subscript(name: String) -> Body? {
        if star.name == name {
            return star
        }
        return star[name]
    }
}

class NonEmittingBody: CelestialBody {
    
}

class Planet: NonEmittingBody {
    
}

class Asteroid: NonEmittingBody {
    
}
