//
//  Constants.swift
//  Graviton
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit

let earthAxialTilt: Double = 23.4 / 180 * M_PI

let gravConstant: Float = 6.67408e-11

// the value is GM, m^3s^-2
enum KnownBody {
    case earth
    case moon
    case sun
    
    var name: String {
        switch self {
        case .earth:
            return "earth"
        case .moon:
            return "moon"
        case .sun:
            return "sol"
        }
    }
    
    var gravParam: Float {
        switch self {
        case .earth:
            return 3.9860044e14
        case .moon:
            return 4.902794e12
        case .sun:
            return 1.3271244e20
        }
    }
    
    var radius: Float {
        switch self {
        case .earth:
            return 6378137
        case .moon:
            return 1736482
        case .sun:
            return 695700000
        }
    }
}

// m
let earthEquatorialRadius: Float = 6378137
let moonRadius: Float = 1736482
let LEOAltitude: Float = 400000
let geoSyncAltitude: Float = 35786000
let moonAltitude: Float = 384472282

// m
let lightSecondDist: Float = speedOfLight * 1
let lightMinuteDist: Float = speedOfLight * 60
let astronomicalUnitDist: Float = 1.4960e11
let lightYearDist: Float = 9.4607e15
let parsecDist: Float = 3.0857e16

// m/s
let speedOfLight: Float = 299792458
