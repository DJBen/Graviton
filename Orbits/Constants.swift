//
//  Constants.swift
//  Orbits
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit

// N*m^2s/kg^2
let gravConstant: Float = 6.67408e-11

let earthYear: Float = 365.256363004 * 3600 * 24

// s
let siderealDay: Float = 23 * 3600 + 56 * 60 + 4

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
