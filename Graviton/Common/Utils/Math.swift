//
//  Math.swift
//  Graviton
//
//  Created by Sihao Lu on 6/15/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil

func wrapAngles(_ eulerAngle: (pitch: Scalar, yaw: Scalar, roll: Scalar)) -> (pitch: Scalar, yaw: Scalar, roll: Scalar) {
    return (
        wrapAngle(eulerAngle.pitch),
        wrapAngle(eulerAngle.yaw),
        wrapAngle(eulerAngle.roll)
    )
}
