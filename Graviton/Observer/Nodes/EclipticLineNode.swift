//
//  EclipticLineNode.swift
//  Graviton
//
//  Created by Ben Lu on 4/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import MathUtil

class EclipticLineNode: LineNode {
    init(earth: CelestialBody, numberOfVertices: Int = 200, rawToModelCoordinateTransform: (Vector3) -> Vector3 = { $0 }) {
        let vertices: [SCNVector3] = Array(0..<numberOfVertices).map { index in
            let offset = Double(index) / Double(numberOfVertices) * Double.pi * 2
            let (position, _) = earth.motion!.stateVectors(fromTrueAnomaly: offset)
            return SCNVector3(rawToModelCoordinateTransform(-position))
        }
        super.init(setting: .showEcliptic, vertices: vertices, color: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1))
        name = "ecliptic"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
