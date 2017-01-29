//
//  EphemerisTest.swift
//  Graviton
//
//  Created by Ben Lu on 1/29/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits

private struct Dependency<T: Equatable>: Equatable, CustomStringConvertible {
    let parent: T
    let child: T
    
    var description: String {
        return "Dependency(\(parent) <- \(child))"
    }
    
    static func ==<T: Equatable>(v1: Dependency<T>, v2: Dependency<T>) -> Bool {
        return v1.parent == v2.parent && v1.child == v2.child
    }
}

class EphemerisTest: XCTestCase {

    func testEphemerisTree() {
        func makeCelesitalBody(id: Int) -> CelestialBody {
            let cb = CelestialBody(naifId: id, name: "blah", gravParam: 123, radius: 343)
            return cb
        }
        func verifyDependencies(ep: Ephemeris, dependencies: [(Int, Int)]) {
            var expectedDependencies = [Dependency<Int>]()
            var queue = [ep.root]
            while queue.isEmpty == false {
                let current = queue.removeFirst()
                let sats = current.satellites as! [CelestialBody]
                for sat in sats {
                    expectedDependencies.append(Dependency<Int>(parent: current.naifId, child: sat.naifId))
                }
                queue.append(contentsOf: sats)
            }
            func convertToDependencies(_ values: [(Int, Int)]) -> [Dependency<Int>] {
                return values.map { Dependency<Int>(parent: $0, child: $1) }
            }
            XCTAssertEqual(expectedDependencies, convertToDependencies(dependencies))
        }
        let bodies = [301, 399, 10, 499, 402, 599, 501, 509, 508].map { makeCelesitalBody(id: $0) }
        let ep = Ephemeris(solarSystemBodies: Set<CelestialBody>(bodies))
        XCTAssertEqual(ep.root.naifId, 10)
        verifyDependencies(ep: ep, dependencies: [(10, 399), (10, 499), (10, 599), (399, 301), (499, 402), (599, 501), (599, 508), (599, 509)])
    }
}
