//
//  SolarSystem.swift
//  Orbits
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime
import StarCatalog

public protocol Searchable {
    subscript(name: String) -> Body? { get }
}

public protocol BoundedByGravity: Searchable {
    var gravParam: Double { get }
    var sphereOfInfluence: Double? { get }
    var satellites: [Body] { get }
    func addSatellite(satellite: Body, motion: OrbitalMotion)
}

open class Body {
    public let name: String
    public weak var centralBody: CelestialBody?
    public var motion: OrbitalMotion?
    public var julianDate: Double = JulianDate.J2000 {
        didSet {
            motion?.julianDate = julianDate
            if let primary = self as? CelestialBody {
                primary.satellites.forEach { $0.julianDate = julianDate }
            }
        }
    }
    public var heliocentricPosition: Vector3 {
        let position = motion?.position ?? Vector3.zero
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
    public let naifId: Int
    public let radius: Double
    public let rotationPeriod: Double
    public let axialTilt: Double
    public let gravParam: Double
    private var orbiterDict = [String: Body]()
    
    public var satellites: [Body] {
        return Array(orbiterDict.values)
    }
    
    public var sphereOfInfluence: Double? {
        guard let primary = centralBody, let distance = motion?.distance else {
            return nil
        }
        return distance * (radius / primary.radius)
    }
    
    public init(naifId: Int, name: String, mass: Double, radius: Double, rotationPeriod: Double = 0, axialTilt: Double = 0) {
        self.naifId = naifId
        self.gravParam = mass * gravConstant
        self.radius = radius
        self.rotationPeriod = rotationPeriod
        self.axialTilt = axialTilt
        super.init(name: name)
    }
    
    public convenience init(naifId: Int, mass: Double, radius: Double, rotationPeriod: Double = 0, axialTilt: Double = 0) {
        let name = NaifCatalog.name(forNaif: naifId)!
        self.init(naifId: naifId, name: name, mass: mass, radius: radius, rotationPeriod: rotationPeriod, axialTilt: axialTilt)
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
    public static var sol: Sun {
        return Sun(naifId: 10, name: "Sun", mass: 1.988544e30, radius: 6.955e5)
    }
    
    public override var heliocentricPosition: Vector3 {
        return Vector3.zero
    }
}
