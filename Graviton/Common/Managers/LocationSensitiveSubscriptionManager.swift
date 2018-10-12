//
//  LocationSensitiveSubscriptionManager.swift
//  Graviton
//
//  Created by Sihao Lu on 5/14/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import Orbits
import UIKit

class LocationSensitiveSubscriptionManager<T>: SubscriptionManager<T> {
    private var locationSubscriptionIdentifier: SubscriptionUUID!

    override init() {
        super.init()
        locationSubscriptionIdentifier = LocationManager.default.subscribe(didUpdate: updateLocation(location:))
    }

    deinit {
        LocationManager.default.unsubscribe(locationSubscriptionIdentifier)
    }

    func updateLocation(location _: CLLocation) {
        // Do not fetch online when city is manually set or in warp mode
        if Timekeeper.default.isWarpActive == false && LocationManager.default.locationOverride == nil {
            // refetch new RTS info if location has significant change
            fetch(mode: .preferLocal)
        }
    }
}
