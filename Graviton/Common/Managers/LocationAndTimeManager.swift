//
//  LocationAndTimeManager.swift
//  Graviton
//
//  Created by Sihao Lu on 6/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpaceTime

class LocationAndTimeManager: NSObject {

    static let `default` = LocationAndTimeManager()
    var subId: SubscriptionUUID!
    private(set) var observerInfo: LocationAndTime?

    /// An override of normal julian date in time warp mode
    var julianDate: JulianDate? {
        didSet {
            guard let observerInfo = self.observerInfo else {
                return
            }
            if oldValue == julianDate {
                return
            }
            self.observerInfo = LocationAndTime(location: observerInfo.location, timestamp: self.julianDate ?? JulianDate.now)
        }
    }

    override init() {
        super.init()
        subId = LocationManager.default.subscribe(didUpdate: { (location) in
            self.observerInfo = LocationAndTime(location: location, timestamp: self.julianDate ?? JulianDate.now)
        })
    }

    deinit {
        LocationManager.default.unsubscribe(subId)
    }
}
