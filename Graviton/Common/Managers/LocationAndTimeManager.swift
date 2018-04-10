//
//  ObserverLocationTimeManager.swift
//  Graviton
//
//  Created by Sihao Lu on 6/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpaceTime

class ObserverLocationTimeManager: NSObject {

    static let `default` = ObserverLocationTimeManager()
    var subId: SubscriptionUUID!
    private(set) var observerInfo: ObserverLocationTime?

    /// An override of normal julian date in time warp mode
    var julianDay: JulianDay? {
        didSet {
            guard let observerInfo = self.observerInfo else {
                return
            }
            if oldValue == julianDay {
                return
            }
            self.observerInfo = ObserverLocationTime(location: observerInfo.location, timestamp: self.julianDay ?? JulianDay.now)
        }
    }

    override init() {
        super.init()
        subId = LocationManager.default.subscribe(didUpdate: { [weak self] (location) in
            self?.observerInfo = ObserverLocationTime(location: location, timestamp: self!.julianDay ?? JulianDay.now)
        })
    }

    deinit {
        LocationManager.default.unsubscribe(subId)
    }
}
