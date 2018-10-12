//
//  EphemerisManager.swift
//  Graviton
//
//  Created by Sihao Lu on 2/19/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import Orbits
import SpaceTime
import UIKit

final class EphemerisManager: SubscriptionManager<Ephemeris> {
    static var globalMode: Horizons.FetchMode = .mixed

    static let `default` = EphemerisManager()

    private static let expirationDuration: Double = 365.4215 * 86400

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(resetToNormalEphemeris), name: Notification.Name(rawValue: "warpReset"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func resetToNormalEphemeris() {
        logger.info("Reset to normal ephemeris")
    }

    func content(for subscription: SubscriptionUUID) -> Ephemeris? {
        guard let sub = subscriptions[subscription] else { return nil }
        return sub.content
    }

    override func subscribe(mode: SubscriptionManager<Ephemeris>.RefreshMode, didLoad: SubscriptionBlock?, didUpdate: SubscriptionBlock?) -> SubscriptionUUID {
        let uuid = SubscriptionUUID()
        subscriptions[uuid] = SubscriptionManager<Ephemeris>.Subscription(identifier: uuid, mode: mode, content: content?.copy() as? Ephemeris, didLoad: didLoad, didUpdate: didUpdate)
        if let eph = content {
            didLoad?(eph)
        }
        return uuid
    }

    override func fetch(mode: Horizons.FetchMode? = nil, forJulianDay requestedJd: JulianDay = JulianDay.now) {
        if isFetching { return }
        isFetching = true
        func customLoad(ephemeris: Ephemeris) {
            ephemeris.updateMotion(using: requestedJd)
            load(content: ephemeris)
        }
        Horizons.shared.fetchEphemeris(mode: mode ?? EphemerisManager.globalMode, update: customLoad(ephemeris:), complete: { _, errors in
            defer {
                self.isFetching = false
            }
            if let errors = errors {
                logger.error(errors)
            }
        })
    }

    override func request(at requestedJd: JulianDay, forSubscription subscriptionId: SubscriptionUUID) {
        if Timekeeper.default.isWarping {
            // ignore update frequency
            guard let sub = subscriptions[subscriptionId] else {
                fatalError("object not subscribed")
            }
            update(subscription: sub, forJulianDay: requestedJd)
            DispatchQueue.main.async {
                sub.didUpdate?(sub.content!)
            }
        } else {
            super.request(at: requestedJd, forSubscription: subscriptionId)
        }
    }

    // have to use fully qualified name otherwise compiler will segfault
    override func update(subscription: SubscriptionManager<Ephemeris>.Subscription, forJulianDay requestedJd: JulianDay) {
        if let eph = content(for: subscription.identifier) {
            if let refTime = eph.referenceTimestamp, let reqTime = eph.timestamp, abs(refTime - reqTime) > EphemerisManager.expirationDuration, Timekeeper.default.isWarping == false {
                logger.info("Ephemeris data outdated. Refetching...")
                fetch(forJulianDay: requestedJd)
            }
            eph.updateMotion(using: requestedJd)
        }
    }
}
