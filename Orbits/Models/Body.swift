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
    subscript(subId: Int) -> Body? { get }
}

public protocol BoundedByGravity: Searchable {
    var gravParam: Double { get }
    var hillSphere: Double? { get }
    var satellites: OrderedSet<Body> { get }
    func addSatellite(satellite: Body)
}

open class Body: Hashable {
    public static func ==(lhs: Body, rhs: Body) -> Bool {
        return lhs.naif == rhs.naif
    }

    public let naif: Naif
    public var naifId: Int {
        return naif.rawValue
    }
    public var hashValue: Int {
        return naif.hashValue
    }
    public let name: String
    private var centerBodyNaifId: Int?
    public var centerBody: CelestialBody? {
        guard let id = centerBodyNaifId else { return nil }
        return CelestialBody.load(naifId: id)
    }
    public var motion: OrbitalMotion?
    public var julianDate: JulianDate = JulianDate.J2000 {
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
    public init(naif: Naif, name: String, centerBodyNaifId: Int? = nil) {
        self.naif = naif
        self.name = name
        self.centerBodyNaifId = centerBodyNaifId
    }
    public func setCenter(naifId: Int?) {
        centerBodyNaifId = naifId
    }
}
