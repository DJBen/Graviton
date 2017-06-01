//
//  LocationManager.swift
//  Graviton
//
//  Created by Sihao Lu on 5/13/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import CoreLocation

typealias LocationRequestResultBlock = () -> Void

class LocationManager: NSObject, CLLocationManagerDelegate {
    typealias SubscriptionBlock = (CLLocation) -> Void

    class Subscription {
        var didUpdate: SubscriptionBlock

        init(didUpdate: @escaping SubscriptionBlock) {
            self.didUpdate = didUpdate
        }
    }

    static let `default` = LocationManager()

    var subscriptions = [SubscriptionUUID: Subscription]()
    var timeZone: TimeZone = TimeZone.current
    var location: CLLocation? {
        return locationManager.location
    }

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000
        manager.pausesLocationUpdatesAutomatically = true
        return manager
    }()

    func startLocationService() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func stopLocationService() {
        locationManager.stopUpdatingLocation()
    }

    func subscribe(didUpdate: @escaping SubscriptionBlock) -> SubscriptionUUID {
        let uuid = UUID()
        let sub = Subscription(didUpdate: didUpdate)
        subscriptions[uuid] = sub
        if let location = self.location {
            DispatchQueue.main.async {
                didUpdate(location)
            }
        }
        return uuid
    }

    func unsubscribe(_ uuid: SubscriptionUUID) {
        subscriptions[uuid] = nil
    }

    // MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last!
        for (_, sub) in self.subscriptions {
            DispatchQueue.main.async {
                sub.didUpdate(location)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
