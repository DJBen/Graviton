//
//  PlanetDataExtractionTest.swift
//  Graviton
//
//  Created by Ben Lu on 11/27/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import XCTest

class PlanetDataExtractionTest: XCTestCase {
    
    func testPlanetDataExtraction() {
        let path = Bundle.init(for: PlanetDataExtractionTest.self).path(forResource: "planet_example", ofType: nil)!
        let mockData = try! String(contentsOfFile: path, encoding: .utf8)
        print(mockData)
    }
    
}

fileprivate extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
