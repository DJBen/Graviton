//
//  EphemerisMotionManager.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import Orbits
import SpaceTime

final class EphemerisMotionManager: SubscriptionManager<Ephemeris> {

    static var globalMode: Horizons.FetchMode = .mixed

    static let `default` = EphemerisMotionManager()

    private static let expirationDuration: Double = 366 * 86400

    override func subscribe(mode: SubscriptionManager<Ephemeris>.RefreshMode, didLoad: SubscriptionBlock?, didUpdate: SubscriptionBlock?) -> SubscriptionUUID {
        let uuid = SubscriptionUUID()
        subscriptions[uuid] = SubscriptionManager<Ephemeris>.Subscription(mode: mode, content: self.content?.copy() as? Ephemeris, didLoad: didLoad, didUpdate: didUpdate)
        if let eph = content {
            didLoad?(eph)
        }
        return uuid
    }

    override func fetch(mode: Horizons.FetchMode? = nil) {
        if isFetching { return }
        isFetching = true
        func customLoad(ephemeris: Ephemeris) {
            load(content: ephemeris)
        }
        Horizons.shared.fetchEphemeris(mode: mode ?? EphemerisMotionManager.globalMode, update: customLoad(ephemeris:), complete: { _, _ in             self.isFetching = false
        })
    }

    // have to use fully qualified name otherwise compiler will segfault
    override func update(subscription: SubscriptionManager<Ephemeris>.Subscription, forJulianDate requestedJd: JulianDate) {
        if let eph = subscription.content {
            if let refTime = eph.referenceTimestamp, let reqTime = eph.timestamp, abs(refTime.timeIntervalSince(reqTime)) > EphemerisMotionManager.expirationDuration {
                print("Ephemeris data outdated. Refetching...")
                fetch()
            }
            eph.updateMotion(using: requestedJd)
        }
    }
}
