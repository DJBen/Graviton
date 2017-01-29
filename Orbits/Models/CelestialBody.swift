//
//  CelestialBody.swift
//  Graviton
//
//  Created by Ben Lu on 1/28/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation

open class CelestialBody: Body, BoundedByGravity, CustomStringConvertible, Comparable, Hashable {

    public let radius: Double
    public let rotationPeriod: Double
    public let obliquity: Double
    public let gravParam: Double
    public var hillSphere: Double? {
        if let radRp = overridenHillSphereRadiusRp {
            return radRp * radius
        }
        // TODO: implement correct hill sphere
        guard let primary = centerBody, let distance = motion?.distance else { return nil }
        return distance * (radius / primary.radius)
    }
    
    /// mass in kg
    public var mass: Double {
        return gravParam / gravConstant
    }
    
    public private(set) var satellites: [Body] = []
    
    public var description: String {
        return "CelestialBody: { naif: \(naifId), name: \(name), radius(m): \(radius), rotationPeriod(s): \(rotationPeriod), obliquity(radians): \(obliquity), gm: \(gravParam), hillSphere(m): \(hillSphere)}"
    }
    
    public var hashValue: Int {
        return naifId.hashValue
    }
    
    private var overridenHillSphereRadiusRp: Double?
    
    public init(naifId: Int, name: String, gravParam: Double, radius: Double, rotationPeriod: Double = 0, obliquity: Double = 0, centerBodyNaifId: Int? = nil, hillSphereRadRp: Double? = nil) {
        self.gravParam = gravParam
        self.radius = radius
        self.rotationPeriod = rotationPeriod
        self.obliquity = obliquity
        self.overridenHillSphereRadiusRp = hillSphereRadRp
        super.init(naif: Naif(naifId: naifId), name: name, centerBodyNaifId: centerBodyNaifId)
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
    
    public func addSatellite(satellite: Body) {
        satellites.append(satellite)
        satellite.setCenter(naifId: naifId)
    }
    
    public subscript(subId: Int) -> Body? {
        let targets = satellites.filter { $0.naifId == subId }
        if targets.isEmpty == false {
            return targets[0]
        }
        for satellite in satellites {
            guard let orbitable = satellite as? BoundedByGravity else {
                continue
            }
            if let target = orbitable[subId] {
                return target
            }
        }
        return nil
    }
    
    public static func ==(lhs: CelestialBody, rhs: CelestialBody) -> Bool {
        return lhs.naif == rhs.naif
    }
    
    public static func <(lhs: CelestialBody, rhs: CelestialBody) -> Bool {
        return lhs.naif < rhs.naif
    }
}
