//
//  FakeOrbitalMotion.swift
//  Graviton
//
//  Created by Sihao Lu on 7/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
@testable import Orbits
import MathUtil

class FakeOrbitalMotion: OrbitalMotion {
    var mockPosition: Vector3?

    override var position: Vector3! {
        get {
            return mockPosition ?? super.position
        }
        set {
            super.position = newValue
        }
    }

    init(mockPosition: Vector3) {
        self.mockPosition = mockPosition
        super.init(orbit: Orbit(semimajorAxis: 322, eccentricity: 0.1, inclination: 0.04, longitudeOfAscendingNode: 1.3, argumentOfPeriapsis: 0.2), gm: 123, phase: .timeSincePeriapsis(32))
    }
}
