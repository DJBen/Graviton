//
//  DBHelper.swift
//  Orbits
//
//  Created by Sihao Lu on 1/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SQLite
import SpaceTime

fileprivate let celestialBody = Table("celestial_body")
fileprivate let cbId = Expression<Int64>("naifId")
fileprivate let cusName = Expression<String?>("customName")
fileprivate let obliquityExpr = Expression<Double>("obliquity")
fileprivate let gmExpr = Expression<Double>("gm")
fileprivate let hillSphereExpr = Expression<Double?>("hillSphere")
fileprivate let radiusExpr = Expression<Double>("radius")
fileprivate let rotationPeriodExpr = Expression<Double>("rotationPeriod")
fileprivate let centerBodyId = Expression<Int64?>("centerBodyNaifId")

fileprivate let orbitalMotion = Table("orbital_motion")
fileprivate let obId = Expression<Int64>("ob_id")
fileprivate let bodyId = Expression<Int64>("body_id")
fileprivate let systemGm = Expression<Double?>("system_gm")
fileprivate let a = Expression<Double>("a")
fileprivate let ec = Expression<Double>("ec")
fileprivate let i = Expression<Double>("i")
fileprivate let om = Expression<Double>("om")
fileprivate let w = Expression<Double>("w")
fileprivate let tp = Expression<Double>("tp") // time of periapsis passage, only when mode = 2
fileprivate let refJd = Expression<Double>("ref_jd") // reference jd, only when mode = 2

class DBHelper {
    
    static let shared: DBHelper = setupDatabaseHelper()
    
    class func setupDatabaseHelper() -> DBHelper {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        
        print(path)
        let cb = try! Connection("\(path)/celestialBodies.sqlite3")
        let ob = try! Connection("\(path)/orbitalMotions.sqlite3")
        let helper = DBHelper(celestialBodies: cb, orbitalMotions: ob)
        helper.prepareTables()
        return helper
    }
    
    init(celestialBodies: Connection, orbitalMotions: Connection) {
        self.celestialBodies = celestialBodies
        self.orbitalMotions = orbitalMotions
        self.backupCb = try! Connection(Bundle(for: DBHelper.self).path(forResource: "celestialBodies", ofType: "sqlite3")!)
        self.backupOb = try! Connection(Bundle(for: DBHelper.self).path(forResource: "orbitalMotions", ofType: "sqlite3")!)
    }
    
    let celestialBodies: Connection
    let orbitalMotions: Connection
    let backupCb: Connection
    let backupOb: Connection

    // EC     Eccentricity, e
    // IN     Inclination w.r.t XY-plane, i (degrees)
    // OM     Longitude of Ascending Node, OMEGA, (degrees)
    // W      Argument of Perifocus, w (degrees)
    // Tp     Time of periapsis (Julian Day Number)
    // MA     Mean anomaly, M (degrees)
    // A      Semi-major axis, a (km)
    
    func prepareTables() {
        try! orbitalMotions.run(orbitalMotion.create(ifNotExists: true) { t in
            t.column(obId, primaryKey: .autoincrement)
            t.column(bodyId)
            t.column(systemGm)
            t.column(a)
            t.column(ec)
            t.column(i)
            t.column(om)
            t.column(w)
            t.column(tp)
            t.column(refJd)
            t.unique(bodyId, refJd)
        })

        try! celestialBodies.run(celestialBody.create(ifNotExists: true) { t in
            t.column(cbId, primaryKey: true)
            t.column(cusName)
            t.column(obliquityExpr)
            t.column(gmExpr)
            t.column(hillSphereExpr)
            t.column(radiusExpr)
            t.column(centerBodyId)
            t.column(rotationPeriodExpr)
        })
    }
    
    func saveCelestialBody(_ body: CelestialBody, shouldSaveMotion: Bool) {
        let setters: [Setter] = [cbId <- Int64(body.naifId), gmExpr <- body.gravParam, obliquityExpr <- body.obliquity, radiusExpr <- body.radius, hillSphereExpr <- body.hillSphere, rotationPeriodExpr <- body.rotationPeriod, centerBodyId <- wrapInt(body.centerBody?.naifId)]
        var nameSetter: [Setter] = []
        if NaifCatalog.name(forNaif: body.naifId) == nil {
            nameSetter = [cusName <- body.name]
        }
        try! celestialBodies.run(celestialBody.insert(or: .replace, setters + nameSetter))
        if let obm = body.motion as? OrbitalMotionMoment, shouldSaveMotion {
            obm.save(forBodyId: body.naifId)
        }
    }
    
    func loadCelestialBody(withNaifId naifId: Int, shouldLoadMotion: Bool = true) -> CelestialBody? {
        if naifId == Star.sun.naifId {
            return Star.sun
        }
        func constructResult(_ result: Row) -> CelestialBody {
            if let customName = result.get(cusName) {
                return CelestialBody(naifId: Int(result.get(cbId)), name: customName, gravParam: result.get(gmExpr), radius: result.get(radiusExpr), rotationPeriod: result.get(rotationPeriodExpr), obliquity: result.get(obliquityExpr), centerBodyNaifId: unwrapInt64(result.get(centerBodyId)), hillSphereRadRp: result.get(hillSphereExpr))
            }
            let cb = CelestialBody(naifId: Int(result.get(cbId)), gravParam: result.get(gmExpr), radius: result.get(radiusExpr), rotationPeriod: result.get(rotationPeriodExpr), obliquity: result.get(obliquityExpr), centerBodyNaifId: unwrapInt64(result.get(centerBodyId)), hillSphereRadRp: result.get(hillSphereExpr))
            if shouldLoadMotion {
                cb.motion = self.loadOrbitalMotionMoment(bodyId: naifId, optimalJulianDate: JulianDate.now().value)
            }
            return cb
        }
        let query = celestialBody.filter(cbId == Int64(naifId))
        if let result = try! celestialBodies.pluck(query) {
            return constructResult(result)
        } else if let result = try! backupCb.pluck(query) {
            return constructResult(result)
        } else {
            return nil
        }
    }
    
    func saveOrbitalMotionMoment(_ moment: OrbitalMotionMoment, forBodyId bid: Int) {
        let db: Connection = self.orbitalMotions
        let identitySetter: [Setter] = [bodyId <- Int64(bid), systemGm <- moment.gm, tp <- moment.timeOfPeriapsisPassage!, refJd <- moment.ephemerisJulianDate]
        try! db.run(orbitalMotion.insert(or: .replace, identitySetter + moment.orbit.sqlSaveSetters))
    }
    
    func loadOrbitalMotionMoment(bodyId theBodyId: Int, optimalJulianDate julianDate: Double = JulianDate.now().value) -> OrbitalMotionMoment? {
        let db: Connection = self.orbitalMotions
        let query = orbitalMotion.filter(bodyId == Int64(theBodyId))
        let rows = Array(try! db.prepare(query)) + Array(try! backupOb.prepare(query))
        if rows.isEmpty { return nil }
        var closestRefJdRow: Row!
        for row in rows {
            let referenceJulianDate = row.get(refJd)
            if closestRefJdRow == nil || abs(referenceJulianDate - julianDate) < abs(closestRefJdRow.get(refJd) - julianDate) {
                closestRefJdRow = row
            }
        }
        let (va, vi, vec, vom, vw, vgm) = (closestRefJdRow.get(a), closestRefJdRow.get(i), closestRefJdRow!.get(ec), closestRefJdRow.get(om), closestRefJdRow.get(w), closestRefJdRow.get(systemGm) ?? Star.sun.gravParam)
        let orbit = Orbit(semimajorAxis: va, eccentricity: vec, inclination: vi, longitudeOfAscendingNode: vom, argumentOfPeriapsis: vw)
        let bestRefJd = closestRefJdRow.get(refJd)
        let vtp = closestRefJdRow.get(tp)
        return OrbitalMotionMoment(orbit: orbit, gm: vgm, julianDate: bestRefJd, timeOfPeriapsisPassage: vtp)
    }
}

fileprivate func unwrapInt64(_ v: Int64?) -> Int? {
    if v == nil { return nil }
    return Int(v!)
}

fileprivate func wrapInt(_ v: Int?) -> Int64? {
    if v == nil { return nil }
    return Int64(v!)
}

extension CelestialBody {
    
    /// Save physical properties of the celestial body
    public func save(shouldSaveMotion: Bool = true) {
        DBHelper.shared.saveCelestialBody(self, shouldSaveMotion: shouldSaveMotion)
    }
    
    public class func load(naifId: Int) -> CelestialBody? {
        return DBHelper.shared.loadCelestialBody(withNaifId: naifId)
    }
}

extension OrbitalMotionMoment {
    public func save(forBodyId theBodyId: Int) {
        DBHelper.shared.saveOrbitalMotionMoment(self, forBodyId: theBodyId)
    }
    
    public class func load(bodyId: Int) -> OrbitalMotionMoment? {
        return DBHelper.shared.loadOrbitalMotionMoment(bodyId: bodyId)
    }
}

fileprivate extension Orbit {
    var sqlSaveSetters: [Setter] {
        return [a <- shape.semimajorAxis, ec <- shape.eccentricity, w <- orientation.argumentOfPeriapsis, i <- orientation.inclination, om <- orientation.longitudeOfAscendingNode]
    }
}

extension Connection {
    public var userVersion: Int32 {
        get { return Int32(try! scalar("PRAGMA user_version") as! Int64)}
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
}
