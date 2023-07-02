//
//  Star.swift
//  Orbits
//
//  Created by Ben Lu on 2/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import MathUtil
import SQLite
import Regex

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

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
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

        public var hrIdString: String? {
            return hrId != nil ? "HR \(hrId!)" : nil
        }

        public var hipIdString: String? {
            return hipId != nil ? "HIP \(hipId!)" : nil
        }

        public var hdIdString: String? {
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
            self.spectralType = spect.flatMap(SpectralType.init)
            self.apparentMagnitude = apparentMagnitude
            self.absoluteMagnitude = absoluteMagnitude
            self.distance = distance
            self.luminosity = luminosity
            self.coordinate = coordinate
            self.properMotion = motion
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identity)
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
        let identity = Star.Identity(id: try! row.get(StarryNight.Stars.dbInternalId), hipId: try! row.get(StarryNight.Stars.dbHip), hrId: try! row.get(StarryNight.Stars.dbHr), hdId: try! row.get(StarryNight.Stars.dbHd), gl: try! row.get(StarryNight.Stars.dbGl), bfDesig: try! row.get(StarryNight.Stars.dbBFDesignation), proper: try! row.get(StarryNight.Stars.dbProperName), constellationIAU: try! row.get(StarryNight.Stars.dbCon))
        let coord = Vector3(try! row.get(StarryNight.Stars.dbX), try! row.get(StarryNight.Stars.dbY), try! row.get(StarryNight.Stars.dbZ))
        let vel = Vector3(try! row.get(StarryNight.Stars.dbVx), try! row.get(StarryNight.Stars.dbVy), try! row.get(StarryNight.Stars.dbVz))
        let phys = Star.PhysicalInfo(spect: try! row.get(StarryNight.Stars.dbSpect), apparentMagnitude: try! row.get(StarryNight.Stars.dbMag), absoluteMagnitude: try! row.get(StarryNight.Stars.dbAbsMag), luminosity: try! row.get(StarryNight.Stars.dbLum), distance: try! row.get(StarryNight.Stars.dbDist), coordinate: coord, motion: vel)
        self.init(identity: identity, physicalInfo: phys)
    }

    public static func magitudeLessThan(_ magCutoff: Double) -> [Star] {
        let query = StarryNight.Stars.table
            .filter(StarryNight.Stars.dbMag < magCutoff && StarryNight.Stars.dbInternalId > 0)
            .order(StarryNight.Stars.dbMag.asc)
        do {
            let rows = try StarryNight.db.prepare(query)
            return rows.map { Star(row: $0) }
        } catch {
            return []
        }
    }

    /// Find the closest star to a given cartesian coordinate.
    ///
    /// - Parameters:
    ///   - coordinate: The unit cartesian coordinate converted from equatorial coordinate
    ///   - magCutoff: Maximum magnitude to consider. Any star dimmer than the given magnitude (greater numerically) will be ignored. If set to `nil`, no such filtering takes place.
    ///   - angularDistance: Maximum angular distance to consider in radians.
    /// - Returns: The closest star to a given cartesian coordinate.
    public static func closest(to coordinate: Vector3, maximumMagnitude magCutoff: Double? = nil, maximumAngularDistance angle: RadianAngle? = nil) -> Star? {
        let xSqr = (StarryNight.Stars.dbX / StarryNight.Stars.dbDist - coordinate.x) * (StarryNight.Stars.dbX / StarryNight.Stars.dbDist - coordinate.x)
        let ySqr = (StarryNight.Stars.dbY / StarryNight.Stars.dbDist - coordinate.y) * (StarryNight.Stars.dbY / StarryNight.Stars.dbDist - coordinate.y)
        let zSqr = (StarryNight.Stars.dbZ / StarryNight.Stars.dbDist - coordinate.z) * (StarryNight.Stars.dbZ / StarryNight.Stars.dbDist - coordinate.z)
        let distanceSqr = xSqr + ySqr + zSqr
        let cutoff = magCutoff ?? Double.greatestFiniteMagnitude
        var query = StarryNight.Stars.table.filter(StarryNight.Stars.dbMag < cutoff && StarryNight.Stars.dbInternalId > 0)
        if let angularDistance = angle {
            let maxDistSqr = pow(asin(angularDistance.wrappedValue / 2) * 2, 2)
            query = query.where(distanceSqr < maxDistSqr)
        }
        query = query.order(distanceSqr).limit(1)
        if let row = try? StarryNight.db.pluck(query) {
            return Star(row: row)
        } else {
            return nil
        }
    }

    private static func queryStar(_ query: Table) -> Star? {
        if let row = try? StarryNight.db.pluck(query) {
            return Star(row: row)
        } else {
            return nil
        }
    }

    public static func matches(name: String) -> [Star] {
        if name.isEmpty {
            return []
        }
        let query: Table
        let nonSolar = StarryNight.Stars.dbInternalId > 0
        switch name {
        case Regex("hr\\s*(\\d+)", options: [.ignoreCase]):
            let match = Regex.lastMatch!
            let hr = Int(match.captures[0]!)!
            query = StarryNight.Stars.table.filter(StarryNight.Stars.dbHr == hr && nonSolar)
        case Regex("hd\\s*(\\d+)", options: [.ignoreCase]):
            let match = Regex.lastMatch!
            let hd = Int(match.captures[0]!)!
            query = StarryNight.Stars.table.filter(StarryNight.Stars.dbHd == hd && nonSolar)
        case Regex("hip\\s*(\\d+)", options: [.ignoreCase]):
            let match = Regex.lastMatch!
            let hip = Int(match.captures[0]!)!
            query = StarryNight.Stars.table.filter(StarryNight.Stars.dbHip == hip && nonSolar)
        default:
            query = StarryNight.Stars.table.filter(StarryNight.Stars.dbProperName.like("%\(name)%") && nonSolar)
        }
        return (try? StarryNight.db.prepare(query).map { Star(row: $0) }) ?? []
    }

    public static func hip(_ hip: Int) -> Star? {
        let query = StarryNight.Stars.table.filter(StarryNight.Stars.dbHip == hip)
        return queryStar(query)
    }

    public static func hr(_ hr: Int) -> Star? {
        let query = StarryNight.Stars.table.filter(StarryNight.Stars.dbHr == hr)
        return queryStar(query)
    }

    public static func id(_ id: Int) -> Star? {
        let query = StarryNight.Stars.table.filter(StarryNight.Stars.dbInternalId == id)
        if let row = try? StarryNight.db.pluck(query) {
            return Star(row: row)
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
