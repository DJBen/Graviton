//
//  CelestialEquatorLineNode.swift
//  Graviton
//
//  Created by Ben Lu on 4/12/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import MathUtil

class CelestialEquatorLineNode: LineNode {
    init(earth: CelestialBody, numberOfVertices: Int = 200, rawToModelCoordinateTransform: (Vector3) -> Vector3 = { $0 }) {
        let vertices: [SCNVector3] = Array(0..<numberOfVertices).map { index in
            let offset = Double(index) / Double(numberOfVertices) * Double.pi * 2
            let (position, _) = earth.motion!.stateVectors(fromTrueAnomaly: offset)
            return SCNVector3(rawToModelCoordinateTransform(-position))
        }
        super.init(setting: .showCelestialEquator, vertices: vertices, color: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1))
        name = "celestial equator"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
