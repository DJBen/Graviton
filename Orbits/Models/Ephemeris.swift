//
//  Ephemeris.swift
//  StarCatalog
//
//  Created by Ben Lu on 11/13/16.
//  Copyright © 2016 Ben Lu. All rights reserved.
//

import Foundation
import SpaceTime
import MathUtil

/// Ephemeris is a tree structure with celestial bodies ordered in a way that satellites are always children of their respective primaries.
public class Ephemeris: NSObject, Sequence, NSCopying {
    typealias Node = CelestialBody

    public let root: CelestialBody

    public var timestamp: JulianDay? {
        if let ref = self.first(where: { $0.motion?.julianDay != nil }) {
            return ref.motion!.julianDay!
        }
        return nil
    }

    public var referenceTimestamp: JulianDay? {
        if let ref = self.first(where: { $0.motion?.julianDay != nil }), let mm = ref.motion as? OrbitalMotionMoment {
            return mm.ephemerisJulianDay
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
                    current.centerBody = parent
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

    public func updateMotion(using julianDay: JulianDay = JulianDay.now) {
        for body in self {
            if let moment = body.motion as? OrbitalMotionMoment {
                moment.julianDay = julianDay
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
    public func debugPrintReferenceJulianDayInfo() {
        print("--- ephemeris info ---")
        for body in self {
            if body is Sun { continue }
            guard let motion = body.motion else { continue }
            print("\(body.name): \(motion)")
        }
    }
}

public extension Ephemeris {
    func observedPosition(of origin: CelestialBody, fromObserver observer: CelestialBody) -> Vector3 {
        return observerdPosition(Vector3.zero, relativeTo: origin, fromObserver: observer)
    }

    func observerdPosition(_ position: Vector3, relativeTo reference: CelestialBody? = nil, fromObserver observer: CelestialBody) -> Vector3 {
        let referencePosition: Vector3
        if let reference = reference {
            referencePosition = reference.positionRelativeToSun!
        } else {
            referencePosition = Vector3.zero
        }
        // TODO: obblique only works on earth
        let observedPosition = (referencePosition + position - observer.positionRelativeToSun!).oblique(by: observer.obliquity)
        return observedPosition
    }

    /// Find the body closest to a direction viewed from an observer.
    ///
    /// - Parameters:
    ///   - unitPosition: Unit vector.
    ///   - observer: The observer.
    ///   - maximumAngularDistance: Will ignore bodies with greater angular separation than this value.
    /// - Returns: The closest body to a direction viewed from an observer
    func closestBody(toUnitPosition unitPosition: Vector3, from observer: CelestialBody, maximumAngularDistance: RadianAngle = RadianAngle(Double.pi * 2)) -> CelestialBody? {
        return self.map { [weak self] (targetBody) -> (body: CelestialBody, separation: Double) in
            let vec = self!.observedPosition(of: targetBody, fromObserver: observer).normalized()
            return (targetBody, unitPosition.angularSeparation(from: vec))
        }.filter { (targetBody, separation) -> Bool in
            return observer != targetBody && separation <= maximumAngularDistance.wrappedValue
        }.sorted(by: { $0.1 < $1.1 }).first?.0
    }
}

extension CelestialBody {
    var positionRelativeToSun: Vector3? {
        guard var pos = position else {
            return nil
        }
        var current = self
        while current.centerBody != nil {
            current = current.centerBody!
            pos += current.position!
        }
        return pos
    }

    func commonCentralBody(with other: CelestialBody) -> CelestialBody {
        var list1 = [CelestialBody]()
        var list2 = [CelestialBody]()
        list1.append(self)
        list2.append(other)
        var currentBody = self
        while currentBody.centerBody != nil {
            list1.append(currentBody.centerBody!)
            currentBody = currentBody.centerBody!
        }
        currentBody = other
        while currentBody.centerBody != nil {
            list2.append(currentBody.centerBody!)
            currentBody = currentBody.centerBody!
        }
        for body in list1 {
            if let common = list2.first(where: { $0.naif == body.naif }) {
                return common
            }
        }
        fatalError("Two celestial bodies do not share a common center")
    }
}
