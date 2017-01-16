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
fileprivate let obliquityExpr = Expression<Double>("obliquity")
fileprivate let gmExpr = Expression<Double>("gm")
fileprivate let hillSphereExpr = Expression<Double?>("hiilSphere")
fileprivate let radiusExpr = Expression<Double>("radius")
fileprivate let rotationPeriodExpr = Expression<Double>("rotationPeriod")
fileprivate let centerBodyId = Expression<Int64?>("centerBodyNaifId")

class DBHelper {
    
    static let shared: DBHelper = {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        
        print(path)
        let helper = DBHelper(celestialBodies: try! Connection("\(path)/celestialBodies.sqlite3"))
        helper.prepareTables()
        return helper
    }()
    
    private init(celestialBodies: Connection) {
        self.celestialBodies = celestialBodies
        self.backupCb = try! Connection(Bundle(for: DBHelper.self).path(forResource: "celestialBodies", ofType: "sqlite3")!)
    }
    
    let celestialBodies: Connection
    let backupCb: Connection
    
    // EC     Eccentricity, e
    // IN     Inclination w.r.t XY-plane, i (degrees)
    // OM     Longitude of Ascending Node, OMEGA, (degrees)
    // W      Argument of Perifocus, w (degrees)
    // Tp     Time of periapsis (Julian Day Number)
    // MA     Mean anomaly, M (degrees)
    // A      Semi-major axis, a (km)
    
    func prepareTables() {
//        let orbitalMotion = Table("orbital_motion")
//        let id = Expression<Int64>("id")
//        let mode = Expression<Int64>("mode")
//        let ec = Expression<Double>("ec")
//        let om = Expression<Double>("om")
//        let w = Expression<Double>("w")
//        let m = Expression<Double?>("m") // mean anomaly, only when mode = 0
//        let tsp = Expression<Double?>("tsp") // time since periapsis, only when mode = 1
//        let a = Expression<Double>("a")
//        
//        try database.run(orbitalMotion.create(ifNotExists: true) { t in
//            t.column(id, primaryKey: .autoincrement)
//            t.column(mode)
//            t.column(ec)
//            t.column(om)
//            t.column(w)
//            t.column(m)
//            t.column(tsp)
//            t.column(a)
//        })
//        
//        let moment = Table("orbital_motion_moment")
//        let tp = Expression<Double>("tp") // time of periapsis passage, only when mode = 2
//        let ref_jd = Expression<Double>("ref_jd") // reference jd
//        let moment_id = Expression<Int64>("id")
//        let orbit_id = Expression<Int64>("orbit_id")
//        
//        try database.run(moment.create(ifNotExists: true) { t in
//            t.column(moment_id, primaryKey: .autoincrement)
//            t.column(tp)
//            t.column(ref_jd)
//            t.column(orbit_id, references: orbitalMotion, id)
//            t.foreignKey(orbit_id, references: orbitalMotion, id, update: .cascade, delete: .cascade)
//        })

        try! celestialBodies.run(celestialBody.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(obliquityExpr)
            t.column(gmExpr)
            t.column(hillSphereExpr)
            t.column(radiusExpr)
            t.column(centerBodyId)
            t.column(rotationPeriodExpr)
        })
    
//        Horizons().fetchPlanets { (ephemeris, errors) in
//            guard errors == nil else {
//                print(errors!)
//                return
//            }
//            self.ephemeris = ephemeris!
//            self.fillSolarSystemScene(self.SolarSystemScene)
//        }
//        let result = ResponseParser.parseBodyInfo(PlanetDataExtractionTest.mockData)
        
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
    public func save() {
        let db: Connection = DBHelper.shared.celestialBodies
        try! db.run(celestialBody.insert(or: .replace, id <- Int64(self.naifId), gmExpr <- self.gravParam, obliquityExpr <- self.obliquity, radiusExpr <- self.radius, hillSphereExpr <- self.hillSphere, rotationPeriodExpr <- self.rotationPeriod, centerBodyId <- wrapInt(self.centerBody?.naifId)))
    }
    
    public class func from(naifId: Int) -> CelestialBody? {
        if naifId == Sun.sol.naifId {
            return Sun.sol
        }
        func constructResult(_ result: Row) -> CelestialBody {
            return CelestialBody(naifId: Int(result.get(id)), gravParam: result.get(gmExpr), radius: result.get(radiusExpr), rotationPeriod: result.get(rotationPeriodExpr), obliquity: result.get(obliquityExpr), centerBodyNaifId: unwrapInt64(result.get(centerBodyId)), hillSphereRadRp: result.get(hillSphereExpr))
        }
        let query = celestialBody.filter(id == Int64(naifId))
        if let result = try! DBHelper.shared.celestialBodies.pluck(query) {
            return constructResult(result)
        } else if let result = try! DBHelper.shared.backupCb.pluck(query) {
            return constructResult(result)
        } else {
            return nil
        }
    }
}
