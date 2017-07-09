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
    typealias ObserverInfoSubscriptionBlock = (LocationAndTime) -> Void

    class Subscription {
        var didUpdate: ObserverInfoSubscriptionBlock

        init(didUpdate: @escaping ObserverInfoSubscriptionBlock) {
            self.didUpdate = didUpdate
        }
    }

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
            DispatchQueue.main.async {
                self.subscriptions.forEach { (_, sub) in
                    sub.didUpdate(observerInfo)
                }
            }
        }
    }

    var subscriptions = [SubscriptionUUID: Subscription]()

    override init() {
        super.init()
        subId = LocationManager.default.subscribe(didUpdate: { (location) in
            self.observerInfo = LocationAndTime(location: location, timestamp: self.julianDate ?? JulianDate.now)
            self.subscriptions.forEach({ (_, subscriber) in
                subscriber.didUpdate(self.observerInfo!)
            })
        })
    }

    deinit {
        LocationManager.default.unsubscribe(subId)
    }

    func subscribe(didUpdate: @escaping ObserverInfoSubscriptionBlock) -> SubscriptionUUID {
        let uuid = UUID()
        let sub = Subscription(didUpdate: didUpdate)
        subscriptions[uuid] = sub
        if let observerInfo = self.observerInfo {
            DispatchQueue.main.async {
                didUpdate(observerInfo)
            }
        }
        return uuid
    }

    func unsubscribe(_ uuid: SubscriptionUUID) {
        subscriptions[uuid] = nil
    }
}
