//
//  SceneKit+Util.swift
//  Graviton
//
//  Created by Ben Lu on 6/27/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SceneKit

public let flipTextureContentsTransform: SCNMatrix4 = {
    var mtx = SCNMatrix4MakeTranslation(-0.5, -0.5, 0)
    mtx = SCNMatrix4Rotate(mtx, Float(Double.pi), 0, 0, 1)
    mtx = SCNMatrix4Translate(mtx, 0.5, 0.5, 0)
    return mtx
}()

extension CGPoint {
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }

    func distance(toPoint p: CGPoint) -> CGFloat {
        return sqrt(pow(x - p.x, 2) + pow(y - p.y, 2))
    }
}
