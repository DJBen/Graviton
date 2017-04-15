//
//  EphemerisManager.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import Orbits
import SpaceTime

class EphemerisManager {
    enum RefreshMode {
        case realtime
        case interval(TimeInterval)
    }
    
    let mode: RefreshMode
    private let ephemeris: Ephemeris

    /// Julian date when the ephemeris is last updated
    private var lastUpdatedJd: JulianDate = 0.0
    
    init(mode: RefreshMode, ephemeris: Ephemeris) {
        self.mode = mode
        self.ephemeris = ephemeris
    }
    
    func requestedEphemeris(at requestedJd: JulianDate) -> (Ephemeris, Bool)? {
        var changed = false
        switch mode {
        case .realtime:
            ephemeris.updateMotion(using: requestedJd.date)
            lastUpdatedJd = requestedJd
            changed = true
        case .interval(let interval):
            if requestedJd - lastUpdatedJd >= interval {
                ephemeris.updateMotion(using: requestedJd.date)
                lastUpdatedJd = requestedJd
                changed = true
            }
        }
        return (ephemeris, changed)
    }
}
