//
//  VectorMath+CoreMotion.swift
//  Graviton
//
//  Created by Sihao Lu on 6/12/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SceneKit
import CoreMotion

extension SCNQuaternion {
    public init(_ q: CMQuaternion) {
        self.init(x: SCNFloat(q.x), y: SCNFloat(q.y), z: SCNFloat(q.z), w: SCNFloat(q.w))
    }
}

extension Quaternion {
    public init(_ q: CMQuaternion) {
        self.init(x: q.x, y: q.y, z: q.z, w: q.w)
    }
}
