//
//  CelestialNode.swift
//  Graviton
//
//  Created by Ben Lu on 9/20/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit

class CelestialNode: SCNNode {
    let body: CelestialBody
    
    var materialRotation = matrix_float3x3(columns: (vector_float3(1, 0, 0), vector_float3(0, 0, 1), vector_float3(0, -1, 0)))
    
    var originalEulerAngles: SCNVector3 = SCNVector3Zero
    
    override var eulerAngles: SCNVector3 {
        get {
            return SCNVector3FromFloat3(matrix_multiply(materialRotation, SCNVector3ToFloat3(originalEulerAngles)))
        }
        set {
            originalEulerAngles = SCNVector3FromFloat3(matrix_multiply(matrix_invert(materialRotation), SCNVector3ToFloat3(newValue)))
            super.eulerAngles = newValue
        }
    }
    
    var rotationAxis: SCNVector3 {
        // rotation around y axis
        let θ = -body.axialTilt
        return SCNVector3(x: sin(θ), y: 0, z: cos(θ))
    }
    
    init(body: CelestialBody, geometry: SCNGeometry?) {
        self.body = body
        super.init()
        self.geometry = geometry
    }
    
    convenience init(body: CelestialBody, sphereMaterial: SCNMaterial) {
        let sphere = SCNSphere(radius: 1)
        sphere.materials = [sphereMaterial]
        self.init(body: body, geometry: sphere)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
