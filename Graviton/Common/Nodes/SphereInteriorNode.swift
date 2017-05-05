//
//  SphereInteriorNode.swift
//  Graviton
//
//  Created by Ben Lu on 4/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

class SphereInteriorNode: SCNNode {
    var sphere: SCNSphere {
        return geometry as! SCNSphere
    }

    /// Initialize a sphere interior node
    ///
    /// - Parameters:
    ///   - radius: The radius of the sphere
    ///   - textureLongitudeOffset: the x-offset of texture from zero longitude being x = 0
    init(radius: Double, textureLongitudeOffset: Double = 0) {
        super.init()
        let sphere = SCNSphere(radius: CGFloat(radius))
        sphere.firstMaterial!.cullMode = .back
        sphere.firstMaterial!.locksAmbientWithDiffuse = true
        geometry = sphere
        var mtx = SCNMatrix4MakeRotation(Float(-Double.pi / 2), 1, 0, 0)
        mtx = SCNMatrix4Rotate(mtx, Float(-Double.pi / 2 - textureLongitudeOffset), 0, 1, 0)
        pivot = SCNMatrix4Scale(mtx, -1, 1, 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
