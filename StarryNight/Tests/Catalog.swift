//
//  File.swift
//  
//
//  Created by Jatin Mathur on 7/7/23.
//

import Foundation

import XCTest
@testable import StarryNight
import SpaceTime
import MathUtil

class CatalogTest: XCTestCase {
    func testGetMatches() {
        let matches = get_matches(angle: 0.52359, angle_delta: 0.1)
        XCTAssertNotNil(matches)
    }
}

