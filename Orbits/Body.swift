//
//  SolarSystem.swift
//  Orbits
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import SceneKit
import Time

public protocol Searchable {
    subscript(name: String) -> Body? { get }
}

public protocol BoundedByGravity: Searchable {
    var gravParam: Float { get }
    var sphereOfInfluence: Float? { get }
    var satellites: [Body] { get }
    func addSatellite(satellite: Body, motion: OrbitalMotion)
}

open class Body {
    public let name: String
    public weak var centralBody: CelestialBody?
    public var motion: OrbitalMotion?
    public var julianDate: Float = Float(JulianDate.J2000) {
        didSet {
            motion?.julianDate = julianDate
            if let primary = self as? CelestialBody {
                primary.satellites.forEach { $0.julianDate = julianDate }
            }
        }
    }
    public var heliocentricPosition: SCNVector3 {
        let position = motion?.position ?? SCNVector3()
        if centralBody as? Sun != nil {
            return position
        } else if let primary = centralBody {
            return primary.heliocentricPosition + position
        } else {
            return position
        }
    }
    
    public init(name: String) {
        self.name = name
    }
}

open class CelestialBody: Body, BoundedByGravity {
    public let radius: Float
    public let rotationPeriod: Float
    public let axialTilt: Float
    public let gravParam: Float
    private var orbiterDict = [String: Body]()
    
    public var satellites: [Body] {
        return Array(orbiterDict.values)
    }
    
    public var sphereOfInfluence: Float? {
        guard let primary = centralBody, let distance = motion?.distance else {
            return nil
        }
        return distance * (radius / primary.radius)
    }
    
    public init(name: String, mass: Float, radius: Float, rotationPeriod: Float = 0, axialTilt: Float = 0) {
        self.gravParam = mass * gravConstant
        self.radius = radius
        self.rotationPeriod = rotationPeriod
        self.axialTilt = axialTilt
        super.init(name: name)
    }
    
    public static var sun: Sun {
        return Sun(name: "Sun", mass: 1.988544e30, radius: 6.955e5)
    }
    
    public func addSatellite(satellite: Body, motion: OrbitalMotion) {
        orbiterDict[satellite.name] = satellite
        satellite.centralBody = self
        satellite.motion = motion
    }
    
    public subscript(name: String) -> Body? {
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

open class Sun: CelestialBody {
    public override var heliocentricPosition: SCNVector3 {
        return SCNVector3()
    }
}
