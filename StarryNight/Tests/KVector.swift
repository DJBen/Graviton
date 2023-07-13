//
//  File.swift
//  
//
//  Created by Jatin Mathur on 7/13/23.
//

import Foundation

import XCTest
@testable import StarryNight
import SpaceTime
import MathUtil
import SQLite

class KVectorTest: XCTestCase {
    func testKVectorEasy() {
        
        var data: [(Double, String)] = [(1.0, "a"), (1.7, "b"), (2.9, "c"), (3.1, "d"), (11.7, "e"), (15.0, "f"), (17.9, "g"), (23.5, "h")]
        let kv = KVector(data: &data)

        var res = kv.getData(lower: 0.9, upper: 1.1)
        XCTAssertEqual(res.count, 1)
        XCTAssertEqual(res.first!.0, 1.0)

        res = kv.getData(lower: 22, upper: 3000)
        XCTAssertEqual(res.count, 1)
        XCTAssertEqual(res.first!.0, 23.5)

        res = kv.getData(lower: 2.8, upper: 3.2)
        XCTAssertEqual(res.count, 2)
        XCTAssertEqual(res.map({ $0.0 }), [2.9, 3.1])
        
        res = kv.getData(lower: 2.8, upper: 17.8)
        XCTAssertEqual(res.count, 4)
        XCTAssertEqual(res.map({ $0.0 }), [2.9, 3.1, 11.7, 15.0])
        
        res = kv.getData(lower: 0.9, upper: 1.8)
        XCTAssertEqual(res.count, 2)
        XCTAssertEqual(res.map({ $0.0 }), [1.0, 1.7])
        
        res = kv.getData(lower: 17.8, upper: 5000)
        XCTAssertEqual(res.count, 2)
        XCTAssertEqual(res.map({ $0.0 }), [17.9, 23.5])
    }
    
    func testKVectorHard() {
        let cat = Catalog()
        
        func testLowHigh(lower: Double, upper: Double) {
            let res = cat.kvector.getData(lower: lower, upper: upper)
            let actual = getAllStarAngles(lower: lower, upper: upper)
            XCTAssertEqual(actual.map({ $0.0 }), res.map({ $0.0 }))
        }
        
        testLowHigh(lower: 0.1, upper: 0.2)
        testLowHigh(lower: 0.05, upper: 0.07)
        testLowHigh(lower: 0.23, upper: 0.49)
    }
}
