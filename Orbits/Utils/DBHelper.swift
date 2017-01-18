//
//  DBHelper.swift
//  Graviton
//
//  Created by Sihao Lu on 1/1/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SQLite

fileprivate let celestialBody = Table("celestial_body")
fileprivate let id = Expression<Int64>("naifId")
fileprivate let cusName = Expression<String?>("customName")
fileprivate let obliquityExpr = Expression<Double>("obliquity")
fileprivate let gmExpr = Expression<Double>("gm")
fileprivate let hillSphereExpr = Expression<Double?>("hillSphere")
fileprivate let radiusExpr = Expression<Double>("radius")
fileprivate let rotationPeriodExpr = Expression<Double>("rotationPeriod")
fileprivate let centerBodyId = Expression<Int64?>("centerBodyNaifId")

fileprivate let orbitalMotion = Table("orbital_motion")
fileprivate let obId = Expression<Int64>("id")
fileprivate let bodyId = Expression<Int64>("body_id")
fileprivate let mode = Expression<Int64>("mode")
fileprivate let a = Expression<Double>("a")
fileprivate let ec = Expression<Double>("ec")
fileprivate let i = Expression<Double>("i")
fileprivate let om = Expression<Double>("om")
fileprivate let w = Expression<Double>("w")
fileprivate let m = Expression<Double?>("m") // mean anomaly, only when mode = 0
fileprivate let tsp = Expression<Double?>("tsp") // time since periapsis, only when mode = 1

fileprivate let moment = Table("orbital_motion_moment")
fileprivate let momentId = Expression<Int64?>("moment_id")
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
    }
    
    let celestialBodies: Connection
    let orbitalMotions: Connection
    let backupCb: Connection
    
    // EC     Eccentricity, e
    // IN     Inclination w.r.t XY-plane, i (degrees)
    // OM     Longitude of Ascending Node, OMEGA, (degrees)
    // W      Argument of Perifocus, w (degrees)
    // Tp     Time of periapsis (Julian Day Number)
    // MA     Mean anomaly, M (degrees)
    // A      Semi-major axis, a (km)
    
    func prepareTables() {
        try! orbitalMotions.run(orbitalMotion.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(bodyId)
            t.column(mode)
            t.column(a)
            t.column(ec)
            t.column(i)
            t.column(om)
            t.column(w)
            t.column(m)
            t.column(tsp)
            t.column(momentId, references: orbitalMotion, id)
            t.foreignKey(momentId, references: orbitalMotion, id, update: .cascade, delete: .cascade)
        })
        
        try! orbitalMotions.run(moment.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(tp)
            t.column(refJd)
        })

        try! celestialBodies.run(celestialBody.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
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
        let setters: [Setter] = [id <- Int64(body.naifId), gmExpr <- body.gravParam, obliquityExpr <- body.obliquity, radiusExpr <- body.radius, hillSphereExpr <- body.hillSphere, rotationPeriodExpr <- body.rotationPeriod, centerBodyId <- wrapInt(body.centerBody?.naifId)]
        var nameSetter: [Setter] = []
        if NaifCatalog.name(forNaif: body.naifId) == nil {
            nameSetter = [cusName <- body.name]
        }
        try! celestialBodies.run(celestialBody.insert(or: .replace, setters + nameSetter))
        if shouldSaveMotion {
            body.motion?.save(forBodyId: body.naifId)
        }
    }
    
    func loadCelestialBody(withNaifId naifId: Int) -> CelestialBody? {
        if naifId == Sun.sol.naifId {
            return Sun.sol
        }
        func constructResult(_ result: Row) -> CelestialBody {
            if let customName = result.get(cusName) {
                return CelestialBody(naifId: Int(result.get(id)), name: customName, gravParam: result.get(gmExpr), radius: result.get(radiusExpr), rotationPeriod: result.get(rotationPeriodExpr), obliquity: result.get(obliquityExpr), centerBodyNaifId: unwrapInt64(result.get(centerBodyId)), hillSphereRadRp: result.get(hillSphereExpr))
            }
            return CelestialBody(naifId: Int(result.get(id)), gravParam: result.get(gmExpr), radius: result.get(radiusExpr), rotationPeriod: result.get(rotationPeriodExpr), obliquity: result.get(obliquityExpr), centerBodyNaifId: unwrapInt64(result.get(centerBodyId)), hillSphereRadRp: result.get(hillSphereExpr))
        }
        let query = celestialBody.filter(id == Int64(naifId))
        if let result = try! celestialBodies.pluck(query) {
            return constructResult(result)
        } else if let result = try! backupCb.pluck(query) {
            return constructResult(result)
        } else {
            return nil
        }
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
    
    public class func from(naifId: Int) -> CelestialBody? {
        return DBHelper.shared.loadCelestialBody(withNaifId: naifId)
    }
}

extension OrbitalMotion {
    public func save(forBodyId theBodyId: Int) {
        let db: Connection = DBHelper.shared.orbitalMotions
        let phaseSetters: [Setter]
        var identitySetter: [Setter] = [bodyId <- Int64(theBodyId)]
        if let obm = self as? OrbitalMotionMoment {
            phaseSetters = [mode <- 2]
            identitySetter = [momentId <- try! db.run(moment.insert(or: .replace, tp <- obm.timeOfPeriapsisPassage!, refJd <- obm.ephemerisJulianDate))]
        } else {
            switch phase {
            case .meanAnomaly(let ma):
                phaseSetters = [mode <- 0, m <- ma]
            case .timeSincePeriapsis(let tspRaw):
                phaseSetters = [mode <- 1, tsp <- tspRaw]
            default:
                fatalError()
            }
        }
        try! db.run(orbitalMotion.insert(or: .replace, identitySetter + phaseSetters + orbit.sqlSaveSetters()))
    }
}

fileprivate extension Orbit {
    func sqlSaveSetters() -> [Setter] {
        return [a <- shape.semimajorAxis, ec <- shape.eccentricity, w <- orientation.argumentOfPeriapsis, i <- orientation.inclination, om <- orientation.longitudeOfAscendingNode]
    }
}
