//
//  SolarSystem.swift
//  Orbits
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime
import MathUtil

public protocol Searchable {
    subscript(name: String) -> Body? { get }
}

public protocol BoundedByGravity: Searchable {
    var gravParam: Double { get }
    var hillSphere: Double? { get }
    var satellites: [Body] { get }
    func addSatellite(satellite: Body, motion: OrbitalMotion)
}

open class Body {
    public let name: String
    private var centerBodyNaifId: Int?
    public var centerBody: CelestialBody? {
        guard let id = centerBodyNaifId else { return nil }
        return CelestialBody.from(naifId: id)
    }
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
        if let b = centerBody, b.naifId == Sun.sol.naifId {
            return position
        } else if let primary = centerBody {
            return primary.heliocentricPosition + position
        } else {
            return position
        }
    }
    public init(name: String, centerBodyNaifId: Int? = nil) {
        self.name = name
        self.centerBodyNaifId = centerBodyNaifId
    }
    public func setCenter(naifId: Int?) {
        centerBodyNaifId = naifId
    }
}

open class CelestialBody: Body, BoundedByGravity, CustomStringConvertible, Equatable {
    public let naifId: Int
    public let radius: Double
    public let rotationPeriod: Double
    public let obliquity: Double
    public let gravParam: Double
    public var hillSphere: Double? {
        if let radRp = overridenHillSphereRadiusRp {
            return radRp * radius
        }
        guard let primary = centerBody, let distance = motion?.distance else { return nil }
        return distance * (radius / primary.radius)
    }
    
    /// mass in kg
    public var mass: Double {
        return gravParam / gravConstant
    }
    public var satellites: [Body] {
        return Array(orbiterDict.values)
    }
    
    public var description: String {
        return "CelestialBody: { naif: \(naifId), radius(m): \(radius), rotationPeriod(s): \(rotationPeriod), obliquity(radians): \(obliquity), gm: \(gravParam), hillSphere(m): \(hillSphere)}"
    }
    
    private var orbiterDict = [String: Body]()
    private var overridenHillSphereRadiusRp: Double?
    
    public init(naifId: Int, name: String, gravParam: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centerBodyNaifId: Int? = nil, hillSphereRadRp: Double? = nil) {
        self.naifId = naifId
        self.gravParam = gravParam
        self.radius = radius
        self.rotationPeriod = rotationPeriod
        self.obliquity = obliquity
        self.overridenHillSphereRadiusRp = hillSphereRadRp
        super.init(name: name, centerBodyNaifId: centerBodyNaifId)
    }
    
    public convenience init(naifId: Int, name: String, mass: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centerBodyNaifId: Int? = nil, hillSphereRadRp: Double? = nil) {
        self.init(naifId: naifId, name: name, gravParam: mass * gravConstant, radius: radius, rotationPeriod: rotationPeriod, obliquity: obliquity, centerBodyNaifId: centerBodyNaifId, hillSphereRadRp: hillSphereRadRp)
    }
    
    public convenience init(naifId: Int, mass: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centerBodyNaifId: Int? = nil, hillSphereRadRp: Double? = nil) {
        let name = NaifCatalog.name(forNaif: naifId)!
        self.init(naifId: naifId, name: name, mass: mass, radius: radius, rotationPeriod: rotationPeriod, obliquity: obliquity, centerBodyNaifId: centerBodyNaifId, hillSphereRadRp: hillSphereRadRp)
    }
    
    public convenience init(naifId: Int, gravParam: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centerBodyNaifId: Int? = nil, hillSphereRadRp: Double? = nil) {
        let name = NaifCatalog.name(forNaif: naifId)!
        self.init(naifId: naifId, name: name, gravParam: gravParam, radius: radius, rotationPeriod: rotationPeriod, obliquity: obliquity, centerBodyNaifId: centerBodyNaifId, hillSphereRadRp: hillSphereRadRp)
    }
    
    public func addSatellite(satellite: Body, motion: OrbitalMotion) {
        orbiterDict[satellite.name] = satellite
        satellite.setCenter(naifId: naifId)
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
    
    public static func ==(lhs: CelestialBody, rhs: CelestialBody) -> Bool {
        return lhs.naifId == rhs.naifId
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
