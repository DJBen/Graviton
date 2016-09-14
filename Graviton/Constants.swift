//
//  Constants.swift
//  Graviton
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import SceneKit

let earthAxialTilt: Double = 23.4 / 180 * M_PI

let gravityConstant: CGFloat = 6.67259e-11
let gravity: CGFloat = 9.80665

// g
let massOfEarth: CGFloat = 5.9737e24
let massOfMoon: CGFloat = 7.348e22

let earthGM: CGFloat = 3.986005e14
let moonGM: CGFloat = 4.902794e12

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
