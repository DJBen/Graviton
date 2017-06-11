//
//  EulerAngleTest.swift
//  Graviton
//
//  Created by Sihao Lu on 6/5/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import SpaceTime
import MathUtil

// Verified by http://quaternions.online
class EulerAngleTest: XCTestCase {
    func testEulerAngleQuaternionConversion() {
        let quaternion = Quaternion(0.211, -0.674, 0.079, 0.704)
        let euAngles = EulerAngle(quaternion: quaternion)
        let expectedEulerAngles = EulerAngle(yaw: -1.138, pitch: -1.378, roll: 1.589)
        assertEquals(euAngles, expectedEulerAngles)

        let expectedQuaternion = Quaternion(eulerAngle: EulerAngle(quaternion: quaternion))
        assertEquals(quaternion, expectedQuaternion)
    }
}

private func assertEquals(_ q1: Quaternion, _ q2: Quaternion, accuracy: Double = 1e-2) {
    XCTAssertEqualWithAccuracy(q1.x, q2.x, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(q1.y, q2.y, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(q1.z, q2.z, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(q1.w, q2.w, accuracy: accuracy)
}

private func assertEquals(_ e1: EulerAngle, _ e2: EulerAngle, accuracy: Double = 4e-2) {
    XCTAssertEqualWithAccuracy(e1.yaw, e2.yaw, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(e1.pitch, e2.pitch, accuracy: accuracy)
    XCTAssertEqualWithAccuracy(e1.roll, e2.roll, accuracy: accuracy)
}
