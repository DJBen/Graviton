//
//  ObserverScene+Location.swift
//  Graviton
//
//  Created by Ben Lu on 4/4/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit
import SpaceTime
import CoreLocation
import SceneKit
import MathUtil

typealias LocationRequestResultBlock = () -> Void

extension ObserverScene: CLLocationManagerDelegate {
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
        let lastLocation = locations.last!
        self.observerInfo = ObserverInfo(location: lastLocation, timestamp: Date())
        let orientation = Quaternion(rotationMatrix: observerInfo!.localViewTransform)
        debugNode.orientation = SCNQuaternion(orientation)
        rootNode.childNode(withName: "zenith", recursively: false)!.position = SCNVector3(orientation * Vector3(0, 0, 10))
        rootNode.childNode(withName: "zenith", recursively: false)!.constraints = [SCNBillboardConstraint()]
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
