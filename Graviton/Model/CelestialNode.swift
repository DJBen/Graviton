//
//  CelestialNode.swift
//  Graviton
//
//  Created by Ben Lu on 9/20/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import UIKit
import SceneKit
import Orbits

class CelestialNode: SCNNode {
    let body: CelestialBody
    
    var offsetAngles = SCNVector3(x: Float(M_PI_2), y: 0, z: 0)
    var tilt: SCNVector3 {
        return SCNVector3(x: 0, y: -Float(body.axialTilt), z: 0)
    }
    
    var originalEulerAngles: SCNVector3 = SCNVector3Zero
    
    override var eulerAngles: SCNVector3 {
        get {
            return originalEulerAngles + offsetAngles + tilt
        }
        set {
            originalEulerAngles = newValue - offsetAngles - tilt
            super.eulerAngles = newValue
        }
    }
    
    var rotationAxis: SCNVector3 {
        // rotation around y axis
        let θ = Float(-body.axialTilt)
        return SCNVector3(x: sin(θ), y: 0, z: cos(θ))
    }
    
    init(body: CelestialBody, geometry: SCNGeometry?) {
        self.body = body
        super.init()
        self.geometry = geometry
        self.eulerAngles = originalEulerAngles + offsetAngles + tilt
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
