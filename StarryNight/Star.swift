//
//  Star.swift
//  Orbits
//
//  Created by Ben Lu on 2/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime
import MathUtil
import SQLite

private let stars = Table("stars_7")
// The sun has id 0. Using id > 0 to filter out the sun.
private let dbInternalId = Expression<Int>("id")
private let dbBFDesignation = Expression<String?>("bf")
private let dbHip = Expression<Int?>("hip")
private let dbHr = Expression<Int?>("hr")
private let dbHd = Expression<Int?>("hd")
private let dbGl = Expression<String?>("gl")
private let dbProperName = Expression<String?>("proper")
private let dbX = Expression<Double>("x")
private let dbY = Expression<Double>("y")
private let dbZ = Expression<Double>("z")
private let dbVx = Expression<Double>("vx")
private let dbVy = Expression<Double>("vy")
private let dbVz = Expression<Double>("vz")
private let dbCon = Expression<String>("con")
private let dbSpect = Expression<String?>("spect")
private let dbMag = Expression<Double>("mag")
private let dbAbsMag = Expression<Double>("absmag")
private let dbLum = Expression<Double>("lum")
private let dbDist = Expression<Double>("dist")

public struct Star: Hashable, Equatable {

    public struct Identity: Hashable, Equatable, CustomStringConvertible {
        public let id: Int
        /// The Bayer / Flamsteed designation, primarily from the Fifth Edition of the Yale Bright Star Catalog. This is a combination of the two designations. The Flamsteed number, if present, is given first; then a three-letter abbreviation for the Bayer Greek letter; the Bayer superscript number, if present; and finally, the three-letter constellation abbreviation. Thus Alpha Andromedae has the field value "21Alp And", and Kappa1 Sculptoris (no Flamsteed number) has "Kap1Scl".
        public let rawBfDesignation: String?
        /// The star's ID in the Hipparcos catalog, if known.
        public let hipId: Int?
        /// The star's ID in the Harvard Revised catalog, which is the same as its number in the Yale Bright Star Catalog.
        public let hrId: Int?
        /// The star's ID in the Henry Draper catalog, if known.
        public let hdId: Int?
        public let gl: String?
        /// A common name for the star, such as "Barnard's Star" or "Sirius". I have taken these names primarily from the Hipparcos project's web site, which lists representative names for the 150 brightest stars and many of the 150 closest stars. I have added a few names to this list. Most of the additions are designations from catalogs mostly now forgotten (e.g., Lalande, Groombridge, and Gould ["G."]) except for certain nearby stars which are still best known by these designations.
        public let properName: String?
        /// The standard constellation
        public let constellation: Constellation

        public var hashValue: Int {
            return id.hashValue
        }

        init(id: Int, hipId: Int?, hrId: Int?, hdId: Int?, gl: String?, bfDesig: String?, proper: String?, constellationIAU: String) {
            self.id = id
            self.hipId = hipId
            self.hrId = hrId
            self.hdId = hdId
            self.gl = nilIfEmpty(gl)
            self.rawBfDesignation = nilIfEmpty(bfDesig)
            self.properName = nilIfEmpty(proper)
            self.constellation = Constellation.iau(constellationIAU)!
        }

        public static func ==(lhs: Identity, rhs: Identity) -> Bool {
            return lhs.id == rhs.id
        }

        private var hrIdString: String? {
            return hrId != nil ? "HR \(hrId!)" : nil
        }

        private var hipIdString: String? {
            return hipId != nil ? "HIP \(hipId!)" : nil
        }

        private var hdIdString: String? {
            return hdId != nil ? "HD \(hdId!)" : nil
        }

        public var bayerFlamsteedDesignation: String? {
            guard let bf = rawBfDesignation else {
                return nil
            }
            let bayerFlamsteed = BayerFlamsteed(bf)!
            return String(describing: bayerFlamsteed)
        }

        public var description: String {
            return properName ?? bayerFlamsteedDesignation ?? gl ?? hrIdString ?? hdIdString ?? hipIdString!
        }
    }

    public struct PhysicalInfo {
        /// Raw spectral type in string
        let rawSpectralType: String?
        /// The star's spectral type, if known.
        public let spectralType: SpectralType?
        /// The star's apparent magnitude.
        public let apparentMagnitude: Double
        /// The Cartesian coordinates of the star, in a system based on the equatorial coordinates as seen from Earth. +X is in the direction of the vernal equinox (at epoch 2000), +Z towards the north celestial pole, and +Y in the direction of R.A. 6 hours, declination 0 degrees.
        public let coordinate: Vector3
        ///  The Cartesian velocity components of the star, in the same coordinate system described immediately above. They are determined from the proper motion and the radial velocity (when known). The velocity unit is parsecs per year; these are small values (around 1 millionth of a parsec per year), but they enormously simplify calculations using parsecs as base units for celestial mapping.
        public let properMotion: Vector3
        /// The star's absolute magnitude
        public let absoluteMagnitude: Double
        /// The star's luminosity
        public let luminosity: Double
        public let distance: Double

        init(spect: String?, apparentMagnitude: Double, absoluteMagnitude: Double, luminosity: Double, distance: Double, coordinate: Vector3, motion: Vector3) {
            self.rawSpectralType = spect
            self.spectralType = (spect != nil ? SpectralType(spect!) : nil)
            self.apparentMagnitude = apparentMagnitude
            self.absoluteMagnitude = absoluteMagnitude
            self.distance = distance
            self.luminosity = luminosity
            self.coordinate = coordinate
            self.properMotion = motion
        }
    }

    // Mapping from id to Star object
    private static var cachedStars: [Int: Star] = [:]

    public var hashValue: Int {
        return identity.hashValue
    }

    public let identity: Identity
    public let physicalInfo: PhysicalInfo

    public static func ==(lhs: Star, rhs: Star) -> Bool {
        return lhs.identity == rhs.identity
    }

    private init(identity: Identity, physicalInfo: PhysicalInfo) {
        self.identity = identity
        self.physicalInfo = physicalInfo
    }

    private init(row: Row) {
        let identity = Star.Identity(id: row.get(dbInternalId), hipId: row.get(dbHip), hrId: row.get(dbHr), hdId: row.get(dbHd), gl: row.get(dbGl), bfDesig: row.get(dbBFDesignation), proper: row.get(dbProperName), constellationIAU: row.get(dbCon))
        let coord = Vector3(row.get(dbX), row.get(dbY), row.get(dbZ))
        let vel = Vector3(row.get(dbVx), row.get(dbVy), row.get(dbVz))
        let phys = Star.PhysicalInfo(spect: row.get(dbSpect), apparentMagnitude: row.get(dbMag), absoluteMagnitude: row.get(dbAbsMag), luminosity: row.get(dbLum), distance: row.get(dbDist), coordinate: coord, motion: vel)
        self.init(identity: identity, physicalInfo: phys)
    }

    public static func magitudeLessThan(_ magCutoff: Double) -> [Star] {
        let query = stars.filter(dbMag < magCutoff && dbInternalId > 0).order(dbMag.asc)
        let rows = try! db.prepare(query)
        return rows.map { Star(row: $0) }
    }

    /// Find the closest star to a given cartesian coordinate.
    ///
    /// - Parameters:
    ///   - coordinate: The unit cartesian coordinate converted from equatorial coordinate
    ///   - magCutoff: Maximum magnitude to consider. Any star dimmer than the given magnitude (greater numerically) will be ignored. If set to `nil`, no such filtering takes place.
    ///   - angle: Maximum angular distance to consider.
    /// - Returns: The closest star to a given cartesian coordinate.
    public static func closest(to coordinate: Vector3, maximumMagnitude magCutoff: Double? = nil, maximumAngularDistance angle: Double? = nil) -> Star? {
        let xSqr = (dbX / dbDist - coordinate.x) * (dbX / dbDist - coordinate.x)
        let ySqr = (dbY / dbDist - coordinate.y) * (dbY / dbDist - coordinate.y)
        let zSqr = (dbZ / dbDist - coordinate.z) * (dbZ / dbDist - coordinate.z)
        let distanceSqr = xSqr + ySqr + zSqr
        let cutoff = magCutoff ?? Double.greatestFiniteMagnitude
        var query = stars.filter(dbMag < cutoff && dbInternalId > 0)
        if let ang = angle {
            let maxDistSqr = pow(asin(ang / 2) * 2, 2)
            query = query.where(distanceSqr < maxDistSqr)
        }
        query = query.order(distanceSqr).limit(1)
        if let row = try! db.pluck(query) {
            return Star(row: row)
        } else {
            return nil
        }
    }

    private static func queryStar(_ query: Table) -> Star? {
        if let row = try! db.pluck(query) {
            let id = row.get(dbInternalId)
            if let cachedStar = cachedStars[id] {
                return cachedStar
            }
            let star = Star(row: row)
            cachedStars[id] = star
            return star
        } else {
            return nil
        }
    }

    public static func hip(_ hip: Int) -> Star? {
        let query = stars.filter(dbHip == hip)
        return queryStar(query)
    }

    public static func hr(_ hr: Int) -> Star? {
        let query = stars.filter(dbHr == hr)
        return queryStar(query)
    }

    public static func id(_ id: Int) -> Star? {
        if let cachedStar = cachedStars[id] {
            return cachedStar
        }
        let query = stars.filter(dbInternalId ==
            id)
        if let row = try! db.pluck(query) {
            let star = Star(row: row)
            cachedStars[id] = star
            return star
        }
        return nil
    }
}

private func nilIfEmpty(_ name: String?) -> String? {
    if let str = name {
        return str.trimmingCharacters(in: .whitespacesAndNewlines) == "" ? nil : str
    }
    return nil
}
