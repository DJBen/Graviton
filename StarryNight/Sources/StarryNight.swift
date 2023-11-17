//
//  StarryNight.swift
//  Graviton
//
//  Created by Sihao Lu on 8/12/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Foundation
import SQLite

enum StarryNight {
    static let db = try! Connection(Bundle.module.path(forResource: "stars", ofType: "sqlite3")!)

    enum Constellations {
        static let table = Table("constellations")
        static let dbName = Expression<String>("constellation")
        static let dbIAUName = Expression<String>("iau")
        static let dbGenitive = Expression<String>("genitive")
        static let constellationLinePath = Bundle.module.path(forResource: "constellation_lines", ofType: "dat")!
    }

    enum Spectral {
        static let table = Table("spectral")
        static let spectralType = Expression<String>("SpT")
        static let temp = Expression<Double>("Teff")
    }

    enum Stars {
        static let table = Table("stars_7")
        // The sun has id 0. Using id > 0 to filter out the sun.
        static let dbInternalId = Expression<Int>("id")
        static let dbBFDesignation = Expression<String?>("bf")
        static let dbHip = Expression<Int?>("hip")
        static let dbHr = Expression<Int?>("hr")
        static let dbHd = Expression<Int?>("hd")
        static let dbGl = Expression<String?>("gl")
        static let dbProperName = Expression<String?>("proper")
        static let dbX = Expression<Double>("x")
        static let dbY = Expression<Double>("y")
        static let dbZ = Expression<Double>("z")
        static let dbVx = Expression<Double>("vx")
        static let dbVy = Expression<Double>("vy")
        static let dbVz = Expression<Double>("vz")
        static let dbCon = Expression<String>("con")
        static let dbSpect = Expression<String?>("spect")
        static let dbMag = Expression<Double>("mag")
        static let dbAbsMag = Expression<Double>("absmag")
        static let dbLum = Expression<Double>("lum")
        static let dbDist = Expression<Double>("dist")
    }

    enum ConstellationBorders {
        static let table = Table("con_border_simple")
        static let dbBorderCon = Expression<String>("con")
        static let dbLowRa = Expression<Double>("low_ra")
        static let dbHighRa = Expression<Double>("high_ra")
        static let dbLowDec = Expression<Double>("low_dec")
        static let fullBorders = Table("constellation_borders")
        static let dbOppoCon = Expression<String>("opposite_con")
    }
    
    enum StarAngles {
        static let table = Table("star_angles")
        static let star1Hr = Expression<Int?>("star1_hr")
        static let star2Hr = Expression<Int?>("star2_hr")
        static let angle = Expression<Double>("angle")
        static let star1_x = Expression<Double>("star1_x")
        static let star1_y = Expression<Double>("star1_y")
        static let star1_z = Expression<Double>("star1_z")
        static let star2_x = Expression<Double>("star2_x")
        static let star2_y = Expression<Double>("star2_y")
        static let star2_z = Expression<Double>("star2_z")
    }
}
