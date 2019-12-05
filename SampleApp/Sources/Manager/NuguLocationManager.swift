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

import NuguInterface

final class NuguLocationManager: NSObject {
    static let shared = NuguLocationManager()
    
    private let locationManager = CLLocationManager()
    
    private var requestLocationPermissionCompletion: (() -> Void)?
    
    /// LocationContext.Current value can not be provided in asynchronous way
    /// So the LocationAgent expects for client to pass lastest cached value of LocationContext.Current
    private var cachedLocationCurrent: LocationContext.Current?
    
    private var locationState: LocationContext.State {
        return CLLocationManager.locationServicesEnabled() ? .available : .unavailable
    }
    
    /// LocationContext.Current should be set and passed as nil when,
    /// LocationContext.State != .available
    /// PermissionContext.Permission.State != .granted
    var locationContext: LocationContext {
        let locationState = self.locationState
        guard locationState == .available else {
            cachedLocationCurrent = nil
            return LocationContext(state: locationState, current: nil)
        }
        return LocationContext(state: locationState, current: cachedLocationCurrent)
    }
    
    override init() {
        super.init()
        
        // Set your own options for effective CLLocationManager usage
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
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
        default: break
        }
    }
    
    func requestLocationPermission(completion: @escaping () -> Void) {
        requestLocationPermissionCompletion = completion
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - CLLocationManagerDelegate

extension NuguLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocationPermissionCompletion?()
        requestLocationPermissionCompletion = nil
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
            cachedLocationCurrent = LocationContext.Current(latitude: String(location.coordinate.latitude), longitude: String(location.coordinate.longitude))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let locationError = error as? CLError else { return }
        switch locationError.code {
        case .locationUnknown: break
        case .denied:
            locationManager.stopUpdatingLocation()
            cachedLocationCurrent = nil
        default:
            cachedLocationCurrent = nil
        }
    }
}
