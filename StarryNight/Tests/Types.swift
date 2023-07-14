//
//  File.swift
//  
//
//  Created by Jatin Mathur on 7/14/23.
//

import Foundation

import XCTest
@testable import StarryNight

class TypesTest: XCTestCase {
    func testDeterministicSet() {
        let ds1 = DeterministicSet<Int>()
        for i in 0..<100 {
            ds1.append(i)
        }
        
        let ds2 = DeterministicSet<Int>()
        for i in 50..<150 {
            ds2.append(i)
        }
        
        // duplicates that should not appear in the intersection later in this test
        ds1.append(59)
        ds1.append(60)
        
        // test set functions
        XCTAssertTrue(ds1.contains(1))
        XCTAssertFalse(ds1.contains(10000))
        
        // test intersect
        let intersect = ds1.intersection(ds2)
        let values = intersect.arrayRepresentation()
        let expectedValues = Array(50..<100)
        XCTAssertEqual(values, expectedValues)
        
        // test iterator
        var itActual = intersect.makeIterator()
        var itExpected = values.makeIterator()
        while let nextActual = itActual.next() {
            let nextExpected = itExpected.next()
            XCTAssertEqual(nextActual, nextExpected)
        }
        // make sure iterator has ended
        XCTAssertNil(itExpected.next())
    }
}

