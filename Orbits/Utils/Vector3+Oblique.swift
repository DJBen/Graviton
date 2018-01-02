//
//  Vector3+Oblique.swift
//  Graviton
//
//  Created by Sihao Lu on 7/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil

extension Vector3 {
    /// Vector rotated around x-axis by celestial body's obliquity
    ///
    /// - Parameter obliquity: Celestial body's obliquity
    /// - Returns: The rotated vector due to obliquity
    public func oblique(by obliquity: DegreeAngle) -> Vector3 {
        return Matrix4(rotation: Vector4(1, 0, 0, RadianAngle(degreeAngle: obliquity).wrappedValue)) * self
    }
}
