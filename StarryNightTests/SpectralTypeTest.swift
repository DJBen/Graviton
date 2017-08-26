//
//  SpectralTypeTest.swift
//  Graviton
//
//  Created by Sihao Lu on 8/26/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import XCTest
import Regex
@testable import StarryNight

class SpectralTypeTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMessSpectralTypeParsing() {
        let data = Star.magitudeLessThan(7).filter { $0.physicalInfo.spectralType != nil }.map { ($0.identity.description, $0.physicalInfo.spectralType!) }
        for (name, spectralType) in data {
            if spectralType.isEmpty {
                continue
            }
            // ignore extended spectral types
            if ["C", "W", "S", "Y", "J", "N"].contains(spectralType.characters.first!) {
                continue
            }
            // ignore white dwarves
            if Regex("(d|D|sd).*").matches(spectralType) {
                continue
            }
            XCTAssertNotNil(SpectralType.init(spectralType), "\(name)'s spectral type \(spectralType) cannot be parsed!")
        }
    }

    func testIndividualCases() {
        SpectralType.init("F7.5IV-V")!.assertEqual(type: "F", subType: "7.5", luminosityClass: "IV-V")
        SpectralType.init("K0III")!.assertEqual(type: "K", subType: "0", luminosityClass: "III")
        SpectralType.init("G5")!.assertEqual(type: "G", subType: "5")
        SpectralType.init("G8III:")!.assertEqual(type: "G", subType: "8", luminosityClass: "III", pecularities: ":")
        SpectralType.init("M0/M1IIICNp")!.assertEqual(type: "M", subType: "0")
        SpectralType.init("B8Ia")!.assertEqual(type: "B", subType: "8", luminosityClass: "Ia")
        SpectralType.init("B1.5IV+...")!.assertEqual(type: "B", subType: "1.5", luminosityClass: "IV", pecularities: "+...")
    }
}

extension SpectralType {
    func assertEqual(type: String, subType: String?, luminosityClass: String? = nil, pecularities: String? = nil) {
        XCTAssertEqual(self.type, type)
        XCTAssertEqual(self.subType, subType)
        XCTAssertEqual(self.luminosityClass, luminosityClass)
        XCTAssertEqual(self.peculiarities, pecularities)
    }
}
