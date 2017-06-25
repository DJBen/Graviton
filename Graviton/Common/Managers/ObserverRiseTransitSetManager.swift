//
//  ObserverRiseTransitSetManager.swift
//  Graviton
//
//  Created by Ben Lu on 5/12/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import Orbits
import SpaceTime
import CoreLocation

final class ObserverRiseTransitSetManager: LocationSensitiveSubscriptionManager<[Naif: RiseTransitSetElevation]> {

    static var globalMode: Horizons.FetchMode = .preferLocal

    static let `default` = ObserverRiseTransitSetManager()

    override func fetch(mode: Horizons.FetchMode? = nil, forJulianDate requestedJd: JulianDate = JulianDate.now) {
        if isFetching { return }
        isFetching = true
        let site = ObserverSite(naif: .majorBody(.earth), location: LocationManager.default.content ?? CLLocation())
        Horizons.shared.fetchRiseTransitSetElevation(preferredDate: requestedJd.date, observerSite: site, mode: mode ?? ObserverRiseTransitSetManager.globalMode, update: { (dict) in
            self.content = dict
            for (_, sub) in self.subscriptions {
                DispatchQueue.main.async {
                    sub.didLoad!(dict)
                }
            }
        }, complete: { (_, _) in
            self.isFetching = false
        })
    }

    override func update(subscription: LocationSensitiveSubscriptionManager<[Naif: RiseTransitSetElevation]>.Subscription, forJulianDate requestedJd: JulianDate) {
        guard let rtse = content?.first?.value else { return }
        if JulianDate.now > rtse.endJd {
            // fetch RTS info for new day
            fetch()
        }
    }
}
