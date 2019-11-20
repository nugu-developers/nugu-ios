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
    
    var locationContext: LocationContext = LocationContext(state: .unknown, current: nil)
    var permissionLocationState: PermissionContext.Permission.State {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return .granted
        case .notDetermined:
            return .undetermined
        case .denied:
            return .denied
        case .restricted:
            return .notSupported
        @unknown default:
            return .notSupported
        }
    }
    
    override init() {
        super.init()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 200
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
    }
}

// MARK: - Internal

extension NuguLocationManager {
    func requestLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default: break
        }
    }
    
    func requestLocationPermission(completion: @escaping () -> Void) {
        requestLocationPermissionCompletion = completion
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - Private

private extension NuguLocationManager {
    func locationState() -> LocationContext.State {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return .available
        case .notDetermined:
            return .unknown
        case .denied, .restricted:
            return .unavailable
        @unknown default:
            return .unknown
        }
    }
    
    func locationCurrent(locations: [CLLocation]) -> LocationContext.Current? {
        guard let location = locations.last else {
            return nil
        }
        return LocationContext.Current(latitude: String(location.coordinate.latitude), longitude: String(location.coordinate.longitude))
    }
}

// MARK: - CLLocationManagerDelegate

extension NuguLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocationPermissionCompletion?()
        requestLocationPermissionCompletion = nil
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let horizontalAccuracy = location.horizontalAccuracy
        if horizontalAccuracy > 0 && horizontalAccuracy < 10000 {
            locationContext = LocationContext(state: locationState(), current: locationCurrent(locations: locations))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let locationError = error as? CLError else {
            locationContext = LocationContext(state: .unknown, current: nil)
            return
        }
        switch locationError.code {
        case .locationUnknown:
            break
        default:
            locationContext = LocationContext(state: .unavailable, current: nil)
        }
    }
}
