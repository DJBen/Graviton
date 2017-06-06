//
//  ObserverInfoManager.swift
//  Graviton
//
//  Created by Sihao Lu on 6/6/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpaceTime

class ObserverInfoManager: NSObject {
    typealias ObserverInfoSubscriptionBlock = (LocationAndTime) -> Void

    class Subscription {
        var didUpdate: ObserverInfoSubscriptionBlock

        init(didUpdate: @escaping ObserverInfoSubscriptionBlock) {
            self.didUpdate = didUpdate
        }
    }

    static let `default` = ObserverInfoManager()
    var subId: SubscriptionUUID!
    private(set) var observerInfo: LocationAndTime?

    var subscriptions = [SubscriptionUUID: Subscription]()

    override init() {
        super.init()
        subId = LocationManager.default.subscribe(didUpdate: { [unowned self] (location) in
            self.observerInfo = LocationAndTime(location: location, timestamp: Date())
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
