//
//  MotionManager.swift
//  Graviton
//
//  Created by Sihao Lu on 6/11/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import CoreMotion

class MotionManager: NSObject {
    typealias SubscriptionBlock = (CMDeviceMotion) -> Void

    static let `default` = MotionManager()
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue.init()

    class Subscription {
        let identifier: SubscriptionUUID
        let didUpdate: SubscriptionBlock?

        init(identifier: SubscriptionUUID, didUpdate: SubscriptionBlock?) {
            self.identifier = identifier
            self.didUpdate = didUpdate
        }
    }

    override init() {
        super.init()
        motionManager.deviceMotionUpdateInterval = 1 / 60
        queue.name = "motion-manager"
    }

    var subscriptions = [SubscriptionUUID: Subscription]()

    var content: CMDeviceMotion? {
        return motionManager.deviceMotion
    }

    var isActive: Bool {
        return motionManager.isDeviceMotionActive
    }

    func subscribe(didUpdate: MotionManager.SubscriptionBlock?) -> SubscriptionUUID {
        let uuid = SubscriptionUUID()
        subscriptions[uuid] = Subscription(identifier: uuid, didUpdate: didUpdate)
        if let content = content {
            DispatchQueue.main.async {
                didUpdate?(content)
            }
        }
        return uuid
    }

    func unsubscribe(_ uuid: SubscriptionUUID) {
        subscriptions[uuid] = nil
    }

    func startMotionUpdate() {
        if motionManager.isDeviceMotionActive == false {
            motionManager.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: queue) { (motion, error) in
                if let error = error as? CMError {
                    if error == CMErrorTrueNorthNotAvailable {
                        // ignore
                    } else {
                        print("motion manager failed due to unhandled error \(error)")
                    }
                    return
                } else if let error = error {
                    print(error)
                    return
                }
                if let motion = motion {
                    DispatchQueue.main.async {
                        self.subscriptions.forEach { (_, subscription) in
                            subscription.didUpdate?(motion)
                        }
                    }
                }
            }
            print("Device motion update started")
        }
    }

    func stopMotionUpdate() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
            print("Device motion update stopped")
        }
    }

    func toggleMotionUpdate() {
        if motionManager.isDeviceMotionActive {
            stopMotionUpdate()
        } else {
            startMotionUpdate()
        }
    }
}
