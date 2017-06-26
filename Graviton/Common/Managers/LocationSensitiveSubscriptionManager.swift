//
//  LocationSensitiveSubscriptionManager.swift
//  Graviton
//
//  Created by Sihao Lu on 5/14/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import CoreLocation
import Orbits

class LocationSensitiveSubscriptionManager<T>: SubscriptionManager<T> {
    private var locationSubscriptionIdentifier: SubscriptionUUID!

    override init() {
        super.init()
        locationSubscriptionIdentifier = LocationManager.default.subscribe(didUpdate: updateLocation(location:))
    }

    deinit {
        LocationManager.default.unsubscribe(locationSubscriptionIdentifier)
    }

    func updateLocation(location: CLLocation) {
        if Timekeeper.default.isWarping == false {
            // refetch new RTS info if location has significant change
            fetch(mode: .preferLocal)
        }
    }
}
