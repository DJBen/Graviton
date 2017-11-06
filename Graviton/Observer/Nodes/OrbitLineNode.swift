//
//  OrbitLineNode.swift
//  Graviton
//
//  Created by Sihao Lu on 10/28/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import MathUtil

/// Orbit line node that draws another celestial body's orbit in observer view
class OrbitLineNode: LineNode {

    init(celestialBody: CelestialBody, origin: CelestialBody, ephemeris: Ephemeris, color: UIColor, numberOfVertices: Int = 300, rawToModelCoordinateTransform: (Vector3) -> Vector3 = { $0 }) {
        let vertices: [SCNVector3] = Array(0..<numberOfVertices).map { index in
            let offset = Double(index) / Double(numberOfVertices) * Double.pi * 2
            let (position, _) = celestialBody.motion!.stateVectors(fromTrueAnomaly: offset)
            let observedPosition = ephemeris.observerdPosition(position, relativeTo: celestialBody.centerBody, fromObserver: origin)
            return SCNVector3(rawToModelCoordinateTransform(observedPosition))
        }
        super.init(setting: .showCelestialEquator, vertices: vertices, color: color)
        name = "orbit line for \(celestialBody.naif)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
