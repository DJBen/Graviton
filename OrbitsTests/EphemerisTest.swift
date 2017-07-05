//
//  EphemerisTest.swift
//  Graviton
//
//  Created by Ben Lu on 1/29/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import Orbits
import MathUtil

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

    var ephemeris: Ephemeris!

    override func setUp() {
        let positions = [
            10: Vector3.zero,
            399: Vector3(10, 20, 30),
            499: Vector3(20, 13, 40),
            301: Vector3(1, 1, 1),
            402: Vector3(-2, 3, 2),
            599: Vector3(45, 23, 44),
            501: Vector3(3, 9, -1),
            509: Vector3(10, 10, 10),
            508: Vector3(9, 9, 9)
        ]
        let centerBodies = [
            399: 10,
            499: 10,
            599: 10,
            301: 399,
            402: 499,
            501: 599,
            508: 599,
            509: 599
        ]
        let bodies = [301, 399, 10, 499, 402, 599, 501, 509, 508].map { (id) -> CelestialBody in
            let body: CelestialBody
            if id == 599 {
                body = CelestialBody(naifId: id, name: "blah", gravParam: 123, radius: 343, obliquity: radians(degrees: 12))
            } else {
                body = CelestialBody(naifId: id, name: "blah", gravParam: 123, radius: 343)
            }
            if let pos = positions[id] {
                body.motion = FakeOrbitalMotion(mockPosition: pos)
            }
            return body
        }
        ephemeris = Ephemeris(solarSystemBodies: Set<CelestialBody>(bodies))
        centerBodies.forEach { (bodyId, centerId) in
            ephemeris[bodyId]!.centerBody = ephemeris[centerId]!
        }
    }

    func testEphemerisTree() {
        func verifyDependencies(eph: Ephemeris, dependencies: [(Int, Int)]) {
            var expectedDependencies = [Dependency<Int>]()
            var queue = [eph.root]
            while queue.isEmpty == false {
                let current = queue.removeFirst()
                let sats = Array(current.satellites) as! [CelestialBody]
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
        let bodies = [301, 399, 10, 499, 402, 599, 501, 509, 508].map { CelestialBody(naifId: $0, name: "blah", gravParam: 123, radius: 343) }
        let ep = Ephemeris(solarSystemBodies: Set<CelestialBody>(bodies))
        XCTAssertEqual(ep.root.naifId, 10)
        verifyDependencies(eph: ep, dependencies: [(10, 399), (10, 499), (10, 599), (399, 301), (499, 402), (599, 501), (599, 508), (599, 509)])
    }

    func testRelativePositionCalculations() {
        let position = ephemeris.observedPosition(of: ephemeris[10]!, byObserver: ephemeris[399]!)
        let position2 = ephemeris.observedPosition(of: ephemeris[399]!, byObserver: ephemeris[301]!)
        XCTAssertEqual(position, Vector3(-10, -20, -30))
        XCTAssertEqual(position2, Vector3(-1, -1, -1))
        XCTAssertEqual(ephemeris.observedPosition(of: ephemeris[301]!, byObserver: ephemeris[399]!), Vector3(1, 1, 1))
        XCTAssertEqual(ephemeris.observedPosition(of: ephemeris[399]!, byObserver: ephemeris[10]!), Vector3(10, 20, 30))
        XCTAssertEqual(ephemeris.observedPosition(of: ephemeris[499]!, byObserver: ephemeris[10]!), Vector3(20, 13, 40))
        XCTAssertEqual(ephemeris.observedPosition(of: ephemeris[10]!, byObserver: ephemeris[301]!), Vector3(-11, -21, -31))
        XCTAssertEqual(ephemeris.observedPosition(of: ephemeris[399]!, byObserver: ephemeris[499]!), Vector3(-10, 7, -10))
        XCTAssertEqual(ephemeris.observedPosition(of: ephemeris[499]!, byObserver: ephemeris[399]!), Vector3(10, -7, 10))
    }

    func testClosestBodyQuery() {
        let body = ephemeris.closestBody(toUnitPosition: Vector3(9.9, -7.1, 10.1).normalized(), from: ephemeris[399]!, maximumAngularDistance: radians(degrees: 10))
        XCTAssertEqual(body?.naifId, 499)
        let body2 = ephemeris.closestBody(toUnitPosition: Vector3(-9.5, -19.9, -29.9).normalized(), from: ephemeris[399]!, maximumAngularDistance: radians(degrees: 10))
        XCTAssertEqual(body2?.naifId, 10)
        let body3 = ephemeris.closestBody(toUnitPosition: Vector3(10, 10.1, 9.9).normalized().oblique(by: radians(degrees: 12)), from: ephemeris[599]!, maximumAngularDistance: radians(degrees: 5))
        XCTAssertEqual(body3?.naifId, 509)
        let nilBody = ephemeris.closestBody(toUnitPosition: Vector3(10, 10.1, 9.9).normalized(), from: ephemeris[599]!, maximumAngularDistance: radians(degrees: 5))
        XCTAssertNil(nilBody)

    }
}
