//
//  CelestialNodeTest.swift
//  Graviton
//
//  Created by Ben Lu on 9/20/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest
@testable import Graviton
import SceneKit

class CelestialNodeTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCoordinateConversion() {
        let node = CelestialNode(body: CelestialBody(knownBody: KnownBody.earth), geometry: nil)
        node.eulerAngles = SCNVector3(x: 1, y: 2, z: 3)
        XCTAssertTrue(SCNVector3EqualToVector3(node.eulerAngles, SCNVector3(x: 1, y: 2, z: 3)))
        XCTAssertFalse(SCNVector3EqualToVector3(node.originalEulerAngles, SCNVector3(x: 1, y: 2, z: 3)))
        node.originalEulerAngles = SCNVector3(x: 1, y: 1, z: 0)
        XCTAssertTrue(SCNVector3EqualToVector3(node.eulerAngles, SCNVector3(x: 1, y: 0, z: 1)))
    }
    
}
