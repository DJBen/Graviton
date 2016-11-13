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

protocol AstrodynamicsSupport {
    var body: Body { get }
}

struct SolarSystem: Searchable {
    let star: Sun
    var time: Float = 0 {
        didSet {
            star.time = time
            star.satellites.forEach { $0.time = self.time }
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
