//
//  Ephemeris.swift
//  StarCatalog
//
//  Created by Ben Lu on 11/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime

/// Ephemeris is a tree structure with celestial bodies ordered in a way that satellites are always children of their respective primaries.
public struct Ephemeris: Sequence {
    let root: CelestialBody
    
    init(solarSystemBodies: Set<CelestialBody>) {
        let sortedBodies = solarSystemBodies.sorted()
        guard let first = sortedBodies.first else {
            fatalError("cannot initalize ephemeris from empty celestial bodies")
        }
        root = first
        var parents = [CelestialBody]()
        parents.append(first)
        let remaining = sortedBodies.dropFirst()
        remaining.forEach { (current) in
            repeat {
                if parents.isEmpty {
                    fatalError("solar system bodies missing")
                }
                let parent = parents.last!
                if current.naif.isSatellite(of: parent.naif) {
                    parent.addSatellite(satellite: current)
                    parents.append(current)
                    break
                } else {
                    parents.removeLast()
                }
            } while true
        }
    }
    
    public func makeIterator() -> AnyIterator<CelestialBody> {
        var result = [CelestialBody]()
        var queue = [root]
        while queue.isEmpty == false {
            let current = queue.removeFirst()
            result.append(current)
            let sats = current.satellites as! [CelestialBody]
            queue.append(contentsOf: sats)
        }
        return AnyIterator {
            guard let first = result.first else {
                return nil
            }
            result.removeFirst()
            return first
        }
    }
    
    public func updateMotion(using date: Date = Date()) {
        for body in self {
            if let moment = body.motion as? OrbitalMotionMoment {
                moment.julianDate = JulianDate(date: date).value
            }
        }
    }
    
    public subscript(naifId: Int) -> CelestialBody? {
        for body in self {
            if body.naifId == naifId {
                return body
            }
        }
        return nil
    }
}
