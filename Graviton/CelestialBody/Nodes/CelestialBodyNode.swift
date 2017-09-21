//
//  CelestialBodyNode.swift
//  Graviton
//
//  Created by Sihao Lu on 5/8/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits
import MathUtil

class CelestialBodyNode: SCNNode {

    init(naif: Naif) {
        super.init()
        geometry = naif.geometry
        name = String(naif.rawValue)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension Naif {
    var geometry: SCNGeometry {
        let geometry = SCNSphere(radius: 1)
        geometry.firstMaterial = material
        return geometry
    }

    var material: SCNMaterial {
        let mat = SCNMaterial()
        switch self {
        case .moon(.luna):
            mat.diffuse.contents = #imageLiteral(resourceName: "moon_texture")
//            mat.normal.contents = #imageLiteral(resourceName: "moon_normal")
        default:
            fatalError("Unsupported celestial body")
        }
        return mat
    }
}
