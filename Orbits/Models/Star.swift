//
//  Star.swift
//  Graviton
//
//  Created by Ben Lu on 2/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime
import MathUtil
import SQLite

public class Star: CelestialBody {
    public static var sun: Star {
        return Star(naifId: 10, name: "Sun", mass: 1.988544e30, radius: 6.955e5)
    }
    
    public override var heliocentricPosition: Vector3 {
        return Vector3.zero
    }
}

fileprivate let db = try! Connection(Bundle(for: DBHelper.self).path(forResource: "stars", ofType: "sqlite3")!)
fileprivate let stars = Table("stars_7")
// The sun has id 0. Using id > 0 to filter out the sun.
fileprivate let dbInternalId = Expression<Int>("id")
fileprivate let dbBFDesignation = Expression<String?>("bf")
fileprivate let dbHip = Expression<Int?>("hip")
fileprivate let dbHr = Expression<Int?>("hr")
fileprivate let dbHd = Expression<Int?>("hd")
fileprivate let dbProperName = Expression<String?>("proper")
fileprivate let dbX = Expression<Double>("x")
fileprivate let dbY = Expression<Double>("y")
fileprivate let dbZ = Expression<Double>("z")
fileprivate let dbVx = Expression<Double>("vx")
fileprivate let dbVy = Expression<Double>("vy")
fileprivate let dbVz = Expression<Double>("vz")
fileprivate let dbCon = Expression<String>("con")
fileprivate let dbSpect = Expression<String?>("spect")
fileprivate let dbMag = Expression<Double>("mag")

public struct DistantStar {
    
    public struct Identity: Hashable, Equatable {
        public let id: Int
        /// The Bayer / Flamsteed designation, primarily from the Fifth Edition of the Yale Bright Star Catalog. This is a combination of the two designations. The Flamsteed number, if present, is given first; then a three-letter abbreviation for the Bayer Greek letter; the Bayer superscript number, if present; and finally, the three-letter constellation abbreviation. Thus Alpha Andromedae has the field value "21Alp And", and Kappa1 Sculptoris (no Flamsteed number) has "Kap1Scl".
        public let bayerFlamsteedDesignation: String?
        /// The star's ID in the Hipparcos catalog, if known.
        public let hipId: Int?
        /// The star's ID in the Harvard Revised catalog, which is the same as its number in the Yale Bright Star Catalog.
        public let hrId: Int?
        /// The star's ID in the Henry Draper catalog, if known.
        public let hdId: Int?
        /// A common name for the star, such as "Barnard's Star" or "Sirius". I have taken these names primarily from the Hipparcos project's web site, which lists representative names for the 150 brightest stars and many of the 150 closest stars. I have added a few names to this list. Most of the additions are designations from catalogs mostly now forgotten (e.g., Lalande, Groombridge, and Gould ["G."]) except for certain nearby stars which are still best known by these designations.
        public let properName: String?
        /// The standard constellation
        public let constellation: Constellation
        
        public var hashValue: Int {
            return id.hashValue
        }
        
        init(id: Int, hipId: Int?, hrId: Int?, hdId: Int?, bfDesig: String?, proper: String?, constellationIAU: String) {
            self.id = id
            self.hipId = hipId
            self.hrId = hrId
            self.hdId = hdId
            self.bayerFlamsteedDesignation = bfDesig
            self.properName = proper
            self.constellation = Constellation.iau(constellationIAU)!
        }
        
        public static func ==(lhs: Identity, rhs: Identity) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    public struct PhysicalInfo {
        /// The star's spectral type, if known.
        public let spectralType: String?
        /// The star's apparent visual magnitude.
        public let magnitude: Double
        /// The Cartesian coordinates of the star, in a system based on the equatorial coordinates as seen from Earth. +X is in the direction of the vernal equinox (at epoch 2000), +Z towards the north celestial pole, and +Y in the direction of R.A. 6 hours, declination 0 degrees.
        public let coordinate: Vector3
        ///  The Cartesian velocity components of the star, in the same coordinate system described immediately above. They are determined from the proper motion and the radial velocity (when known). The velocity unit is parsecs per year; these are small values (around 1 millionth of a parsec per year), but they enormously simplify calculations using parsecs as base units for celestial mapping.
        public let properMotion: Vector3
        
        init(spect: String?, mag: Double, coordinate: Vector3, motion: Vector3)  {
            self.spectralType = spect
            self.magnitude = mag
            self.coordinate = coordinate
            self.properMotion = motion
        }
    }
    
    public let identity: Identity
    public let physicalInfo: PhysicalInfo
    
    private init(identity: Identity, physicalInfo: PhysicalInfo) {
        self.identity = identity
        self.physicalInfo = physicalInfo
    }
    
    private init(row: Row) {
        let identity = DistantStar.Identity(id: row.get(dbInternalId), hipId: row.get(dbHip), hrId: row.get(dbHr), hdId: row.get(dbHd), bfDesig: row.get(dbBFDesignation), proper: row.get(dbProperName), constellationIAU: row.get(dbCon))
        let coord = Vector3(row.get(dbX), row.get(dbY), row.get(dbZ))
        let vel = Vector3(row.get(dbVx), row.get(dbVy), row.get(dbVz))
        let phys = DistantStar.PhysicalInfo(spect: row.get(dbSpect), mag: row.get(dbMag), coordinate: coord, motion: vel)
        self.init(identity: identity, physicalInfo: phys)
    }
    
    public static func magitudeLessThan(_ magCutoff: Double) -> [DistantStar] {
        let query = stars.filter(dbMag < magCutoff).filter(dbInternalId > 0).order(dbMag.asc)
        let rows = try! db.prepare(query)
        return rows.map { DistantStar(row: $0) }
    }
    
    public static func hip(_ hip: Int) -> DistantStar? {
        let query = stars.filter(dbHip == hip)
        if let row = try! db.pluck(query) {
            return DistantStar(row: row)
        }
        return nil
    }
}
