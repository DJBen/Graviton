//
//  SolarSystem.swift
//  Orbits
//
//  Created by Ben Lu on 9/14/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime

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
    public enum CentralBody {
        case naifId(Int)
        case custom(CelestialBody)
        
        public var entity: CelestialBody {
            switch self {
            case .naifId(let id):
                return CelestialBody.from(naifId: id)!
            case .custom(let b):
                return b
            }
        }
    }
    public let name: String
    public var centralBody: CentralBody?
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
        if let b = centralBody, case let CentralBody.naifId(id) = b, id == Sun.sol.naifId {
            return position
        } else if let primary = centralBody {
            return primary.entity.heliocentricPosition + position
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
    public let obliquity: Double
    public let gravParam: Double
    public var hillSphere: Double? {
        if let radRp = overridenHillSphereRadiusRp {
            return radRp * radius
        }
        guard let primary = centralBody, let distance = motion?.distance else { return nil }
        return distance * (radius / primary.entity.radius)
    }
    
    /// mass in kg
    public var mass: Double {
        return gravParam / gravConstant
    }
    public var satellites: [Body] {
        return Array(orbiterDict.values)
    }
    
    private var orbiterDict = [String: Body]()
    private var overridenHillSphereRadiusRp: Double?

    public class func from(naifId: Int) -> CelestialBody? {
        if naifId == Sun.sol.naifId {
            return Sun.sol
        }
        return nil
    }
    
    public init(naifId: Int, name: String, gravParam: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centralBody: CentralBody? = nil, hillSphereRadRp: Double? = nil) {
        self.naifId = naifId
        self.gravParam = gravParam
        self.radius = radius
        self.rotationPeriod = rotationPeriod
        self.obliquity = obliquity
        self.overridenHillSphereRadiusRp = hillSphereRadRp
        super.init(name: name)
        self.centralBody = centralBody
    }
    
    public convenience init(naifId: Int, name: String, mass: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centralBody: CentralBody? = nil, hillSphereRadRp: Double? = nil) {
        self.init(naifId: naifId, name: name, gravParam: mass * gravConstant, radius: radius, rotationPeriod: rotationPeriod, obliquity: obliquity, hillSphereRadRp: hillSphereRadRp)
        self.centralBody = centralBody
    }
    
    public convenience init(naifId: Int, mass: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centralBody: CentralBody? = nil, hillSphereRadRp: Double? = nil) {
        let name = NaifCatalog.name(forNaif: naifId)!
        self.init(naifId: naifId, name: name, mass: mass, radius: radius, rotationPeriod: rotationPeriod, obliquity: obliquity, hillSphereRadRp: hillSphereRadRp)
        self.centralBody = centralBody
    }
    
    public convenience init(naifId: Int, gravParam: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centralBody: CentralBody? = nil, hillSphereRadRp: Double? = nil) {
        let name = NaifCatalog.name(forNaif: naifId)!
        self.init(naifId: naifId, name: name, gravParam: gravParam, radius: radius, rotationPeriod: rotationPeriod, obliquity: obliquity, hillSphereRadRp: hillSphereRadRp)
        self.centralBody = centralBody
    }
    
    public func addSatellite(satellite: Body, motion: OrbitalMotion) {
        orbiterDict[satellite.name] = satellite
        satellite.centralBody = .naifId(self.naifId)
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
