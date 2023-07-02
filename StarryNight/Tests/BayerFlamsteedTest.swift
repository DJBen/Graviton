//
//  BayerFlamsteedTest.swift
//  Graviton
//
//  Created by Sihao Lu on 6/30/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
@testable import StarryNight

class BayerFlamsteedTest: XCTestCase {
    func testGreekLetterConversion() {
        XCTAssertEqual(String(describing: GreekLetter(shortEnglish: "Alp")!), "α")
        XCTAssertEqual(String(describing: GreekLetter(shortEnglish: "Ome")!), "ω")
        XCTAssertEqual(String(describing: GreekLetter(shortEnglish: "Gam")!), "γ")
        XCTAssertEqual(String(describing: GreekLetter(shortEnglish: "Iot")!), "ι")
        XCTAssertEqual(String(describing: GreekLetter(shortEnglish: "Pi")!), "π")
        XCTAssertEqual(String(describing: GreekLetter(shortEnglish: "Tau")!), "τ")
    }

    func testBayerFlamsteedConversion() {
        let bf1 = BayerFlamsteed("10Iot2Cyg")!
        XCTAssertEqual(String(describing: bf1), "10 ι\u{00b2} Cygni")
        let bf2 = BayerFlamsteed("Sig Oct")!
        XCTAssertEqual(String(describing: bf2), "σ Octantis")
        let bf3 = BayerFlamsteed("32Xi Dra")!
        XCTAssertEqual(String(describing: bf3), "32 ξ Draconis")
    }

    func testAllBayerFlamsteedConversions() {
        Star.magitudeLessThan(7).compactMap { $0.identity.rawBfDesignation }.forEach { _ = BayerFlamsteed($0) }
    }
}
