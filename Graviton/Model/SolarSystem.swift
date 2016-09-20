//
//  SolarSystem.swift
//  Graviton
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

protocol AstrodynamicsSupport {
    var body: Body { get }
}

protocol Searchable {
    subscript(name: String) -> Body? { get }
}

protocol BoundedByGravity: Searchable {
    var gravParam: Float { get }
    var sphereOfInfluence: Float? { get }
    var satellites: [Body] { get }
    func addSatellite(satellite: Body, motion: OrbitalMotion)
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

class Body {
    let name: String
    weak var centralBody: CelestialBody?
    var motion: OrbitalMotion?
    var time: Float = 0 {
        didSet {
            motion?.setTime(time)
            if let primary = self as? CelestialBody {
                primary.satellites.forEach { $0.time = time }
            }
        }
    }
    var heliocentricPosition: SCNVector3 {
        let position = motion?.position ?? SCNVector3()
        if centralBody as? Sun != nil {
            return position
        } else if let primary = centralBody {
            return primary.heliocentricPosition + position
        } else {
            return position
        }
    }
    
    init(name: String) {
        self.name = name
    }
}

// space vehicles' gravity field is too weak to be considered computatively significant
class SpaceVehicle: Body {
    
}

class CelestialBody: Body, BoundedByGravity {
    let radius: Float
    let rotationPeriod: Float
    let axialTilt: Float
    let gravParam: Float
    private var orbiterDict = [String: Body]()
    
    var satellites: [Body] {
        return Array(orbiterDict.values)
    }
    
    var sphereOfInfluence: Float? {
        guard let primary = centralBody, let distance = motion?.distance else {
            return nil
        }
        return distance * (radius / primary.radius)
    }
    
    init(name: String, mass: Float, radius: Float, rotationPeriod: Float = 0, axialTilt: Float = 0) {
        self.gravParam = mass * gravConstant
        self.radius = radius
        self.rotationPeriod = rotationPeriod
        self.axialTilt = axialTilt
        super.init(name: name)
    }
    
    init(knownBody: KnownBody) {
        self.gravParam = knownBody.gravParam
        self.radius = knownBody.radius
        self.rotationPeriod = knownBody.rotationPeriod
        self.axialTilt = knownBody.axialTilt
        super.init(name: knownBody.name)
    }
    
    func addSatellite(satellite: Body, motion: OrbitalMotion) {
        orbiterDict[satellite.name] = satellite
        satellite.centralBody = self
        satellite.motion = motion
    }
    
    subscript(name: String) -> Body? {
        if let target = orbiterDict[name] {
            return target
        }
        for satellite in satellites {
            guard let orbitable = satellite as? BoundedByGravity else {
                continue
            }
            if let target = orbitable[name] {
                return target
            }
        }
        return nil
    }
}

class Sun: CelestialBody {
    override var heliocentricPosition: SCNVector3 {
        return SCNVector3()
    }
}

class NonEmittingBody: CelestialBody {
    
}

class Planet: NonEmittingBody {
    
}

class Asteroid: NonEmittingBody {
    
}
