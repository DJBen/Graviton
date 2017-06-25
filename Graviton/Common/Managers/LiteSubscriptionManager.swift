//
//  LiteSubscriptionManager.swift
//  Graviton
//
//  Created by Sihao Lu on 6/11/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

class LiteSubscriptionManager<T>: NSObject {
    typealias SubscriptionBlock = (T) -> Void

    class Subscription {
        let identifier: SubscriptionUUID
        let didUpdate: SubscriptionBlock?

        init(identifier: SubscriptionUUID, didUpdate: SubscriptionBlock?) {
            self.identifier = identifier
            self.didUpdate = didUpdate
        }
    }

    var content: T? {
        fatalError()
    }

    var subscriptions = [SubscriptionUUID: Subscription]()

    /// Subscribe to the content update. Keep the returned unique identifier for
    /// further request or unsubscription.
    /// - Parameters:
    ///   - didUpdate: The block being called when the content is updated.
    /// - Returns: A subscription unique identifier.
    func subscribe(didUpdate: SubscriptionBlock?) -> SubscriptionUUID {
        let uuid = SubscriptionUUID()
        subscriptions[uuid] = Subscription(identifier: uuid, didUpdate: didUpdate)
        if let content = content {
            DispatchQueue.main.async {
                didUpdate?(content)
            }
        }
        return uuid
    }

    /// Unsubscribe from the content update.
    ///
    /// - Parameter uuid: The subscription unique identifier.
    func unsubscribe(_ uuid: SubscriptionUUID) {
        subscriptions[uuid] = nil
    }

    func updateAllSubscribers(_ content: T) {
        for (_, sub) in self.subscriptions {
            DispatchQueue.main.async {
                sub.didUpdate?(content)
            }
        }
    }
}
