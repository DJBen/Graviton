//
//  SCNView+Projection.swift
//  Graviton
//
//  Created by Ben Lu on 2/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SceneKit

extension SCNView {
    func project3dTo2d(_ position: SCNVector3) -> CGPoint {
        let vp = projectPoint(position)
        let viewPosition = CGPoint(x: CGFloat(vp.x), y: CGFloat(vp.y))
        return overlaySKScene!.convertPoint(fromView: viewPosition)
    }
    
    func projectedSize(of node: SCNNode) -> CGSize {
        let min = project3dTo2d(node.boundingBox.min)
        let max = project3dTo2d(node.boundingBox.max)
        return CGSize(width: CGFloat(abs(max.x - min.x)), height: CGFloat(abs(max.y - min.y)))
    }
}
