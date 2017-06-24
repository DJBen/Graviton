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
public class Ephemeris: NSObject, Sequence, NSCopying {
    typealias Node = CelestialBody

    public let root: CelestialBody

    public var timestamp: JulianDate? {
        if let ref = self.first(where: { $0.motion?.julianDate != nil }) {
            return ref.motion!.julianDate!
        }
        return nil
    }

    public var referenceTimestamp: JulianDate? {
        if let ref = self.first(where: { $0.motion?.julianDate != nil }), let mm = ref.motion as? OrbitalMotionMoment {
            return mm.ephemerisJulianDate
        }
        return nil
    }

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

    private init(root: CelestialBody) {
        self.root = root
    }

    public func makeIterator() -> AnyIterator<CelestialBody> {
        var result = [CelestialBody]()
        var queue = [root]
        while queue.isEmpty == false {
            let current = queue.removeFirst()
            result.append(current)
            let sats = Array(current.satellites) as! [CelestialBody]
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

    public func updateMotion(using julianDate: JulianDate = JulianDate.now) {
        for body in self {
            if let moment = body.motion as? OrbitalMotionMoment {
                moment.julianDate = julianDate
            }
        }
    }

    public subscript(naif: Naif) -> CelestialBody? {
        return self.first { $0.naif == naif }
    }

    public subscript(naifId: Int) -> CelestialBody? {
        return self.first { $0.naifId == naifId }

    }

    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        return Ephemeris(root: root.copy() as! CelestialBody)
    }
}

public extension Ephemeris {
    public func debugPrintReferenceJulianDateInfo() {
        print("--- ephemeris info ---")
        for body in self {
            if body is Sun { continue }
            guard let motion = body.motion else { continue }
            print("\(body.name): \(motion)")
        }
    }
}
