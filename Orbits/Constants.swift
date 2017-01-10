//
//  Constants.swift
//  Orbits
//
//  Created by Ben Lu on 9/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

// N*m^2s/kg^2
public let gravConstant: Double = 6.67408e-11

public let earthYear: Double = 365.256363004 * 3600 * 24

// s
public let siderealDay: Double = 23 * 3600 + 56 * 60 + 4

// m
public let earthEquatorialRadius: Double = 6378137
public let moonRadius: Double = 1736482
public let LEOAltitude: Double = 400000
public let geoSyncAltitude: Double = 35786000
public let moonAltitude: Double = 384472282

// m
public let lightSecondDist: Double = speedOfLight * 1
public let lightMinuteDist: Double = speedOfLight * 60
public let astronomicalUnitDist: Double = 1.4960e11
public let lightYearDist: Double = 9.4607e15
public let parsecDist: Double = 3.0857e16

// m/s
public let speedOfLight: Double = 299792458
