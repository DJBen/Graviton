//
//  Constants.swift
//  Graviton
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit

let earthAxialTilt: Double = 23.4 / 180 * M_PI


// m^3s^-2
let earthGM: Float = 3.9860044e14
let moonGM: Float = 4.902794e12

// km
let earthEquatorialRadius: Float = 6378.137
let moonRadius: Float = 1736.482
let LEOAltitude: Float = 400
let geoSyncAltitude: Float = 35786
let moonAltitude: Float = 384472.282

// m
let lightSecondDist: Float = speedOfLight * 1
let lightMinuteDist: Float = speedOfLight * 60
let astronomicalUnitDist: Float = 1.4960e11
let lightYearDist: Float = 9.4607e15
let parsecDist: Float = 3.0857e16

// m/s
let speedOfLight: Float = 299792458
