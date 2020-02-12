//
//  NuguLocationManager.swift
//  SampleApp
//
//  Created by jin kim on 2019/11/20.
//  Copyright © 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CoreLocation

import NuguAgents

final class NuguLocationManager: NSObject {
    static let shared = NuguLocationManager()
    
    private let locationManager = CLLocationManager()
    
    /// `LocationAgent` v1.0 can not be provided in asynchronous way
    /// So the `LocationAgent` expects for client to pass lastest cached value of `LocationInfo`
    var cachedLocationInfo: LocationInfo?
    
    override init() {
        super.init()
        
        // Set your own options for effective `CLLocationManager` usage
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 200
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
    }
}

// MARK: - Internal

extension NuguLocationManager {
    func startUpdatingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            // Do not something
            break
        @unknown default: break
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension NuguLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter updated location with your own proper accuracy limit
        let horizontalAccuracy = location.horizontalAccuracy
        if horizontalAccuracy > 0 && horizontalAccuracy < 10000 {
            cachedLocationInfo = LocationInfo(
                latitude: String(location.coordinate.latitude),
                longitude: String(location.coordinate.longitude)
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let locationError = error as? CLError else { return }
        switch locationError.code {
        case .locationUnknown: break
        case .denied:
            locationManager.stopUpdatingLocation()
            cachedLocationInfo = nil
        default:
            cachedLocationInfo = nil
        }
    }
}
