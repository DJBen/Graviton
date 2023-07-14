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
import LASwift

class CatalogTest: XCTestCase {
    func testGetMatches() {
        let catalog = Catalog()
        let matches = catalog.getMatches(angle: 0.52359, angleDelta: 0.1)
        XCTAssertNotNil(matches)
        XCTAssertTrue(matches.keys.count > 0)
    }
    
    func testGetNearbyStars() {
        let catalog = Catalog()
        
        let angleDelta = 0.03
        
        // easy test, no rotation
        let s = Star.hr(5191)!
        let sCoord = s.physicalInfo.coordinate.normalized()
        let ms = catalog.findNearbyStars(coord: sCoord, angleDelta: angleDelta)
        XCTAssertEqual(ms!.hr, s.identity.hrId)

        // test rotations by first converting to spherical, then applying rotations
        let azi = atan2(sCoord.y, sCoord.x)
        let phi = acos(sCoord.z)

        let newPhi = phi + angleDelta
        let rotVec1 = Vector3(sin(newPhi) * cos(azi), sin(newPhi) * sin(azi), cos(newPhi))
        let msRot1 = catalog.findNearbyStars(coord: rotVec1, angleDelta: angleDelta)
        XCTAssertEqual(msRot1!.hr, s.identity.hrId)

        let newAzi = azi + angleDelta
        let rotVec2 = Vector3(sin(phi) * cos(newAzi), sin(phi) * sin(newAzi), cos(phi))
        let msRot2 = catalog.findNearbyStars(coord: rotVec2, angleDelta: angleDelta)
        XCTAssertEqual(msRot2!.hr, s.identity.hrId)
        
        // invalid rotation
        let invalidAngleDelta = 0.04
        let invalidPhi = phi + invalidAngleDelta
        let rotVec3 = Vector3(sin(invalidPhi) * cos(azi), sin(invalidPhi) * sin(azi), cos(invalidPhi))
        let msRot3 = catalog.findNearbyStars(coord: rotVec3, angleDelta: angleDelta)
        
        // We should either get nil or a star that is not 5191
        if msRot3 != nil {
            XCTAssertNotEqual(msRot3!.hr, s.identity.hrId)
        }
    }
}

