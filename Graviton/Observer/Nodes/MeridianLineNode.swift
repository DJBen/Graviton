//
//  MeridianLineNode.swift
//  Graviton
//
//  Created by Sihao Lu on 12/23/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil
import Orbits
import SceneKit
import SpaceTime
import UIKit

class MeridianLineNode: LineNode {
    init(observerInfo: ObserverLocationTime, numberOfVertices: Int = 200, rawToModelCoordinateTransform: (Vector3) -> Vector3 = { $0 }) {
        let vertices = (0 ..< numberOfVertices).map { (index) -> SCNVector3 in
            let offset = DegreeAngle(Double(index) / Double(numberOfVertices) * 360)
            let equatorialCoordinate = EquatorialCoordinate(horizontalCoordinate: HorizontalCoordinate(azimuth: 0.0, altitude: offset), observerInfo: observerInfo)
            let position = Vector3(equatorialCoordinate: equatorialCoordinate)
            return SCNVector3(rawToModelCoordinateTransform(position))
        }
        super.init(setting: .showMeridian, vertices: vertices, color: #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))
        name = "meridian"
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
