//
//  SCNView+Projection.swift
//  Graviton
//
//  Created by Ben Lu on 2/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import SceneKit

@available(*, deprecated)
struct PointAndVisibility {
    let point: CGPoint
    let visible: Bool
}

extension SCNView {
    @available(*, deprecated)
    func project3dTo2d(_ position: SCNVector3) -> PointAndVisibility {
        let vp = projectPoint(position)
        let viewPosition = CGPoint(x: CGFloat(vp.x), y: CGFloat(vp.y))
        let visible = vp.z > 0 && vp.z < 1
        return PointAndVisibility.init(point: overlaySKScene!.convertPoint(fromView: viewPosition), visible: visible)
    }

    @available(*, deprecated)
    func projectedSize(of node: SCNNode) -> CGSize {
        let min = project3dTo2d(node.boundingBox.min).point
        let max = project3dTo2d(node.boundingBox.max).point
        return CGSize(width: CGFloat(abs(max.x - min.x)), height: CGFloat(abs(max.y - min.y)))
    }
}
