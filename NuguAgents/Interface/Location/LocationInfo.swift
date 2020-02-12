//
//  LocationInfo.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2019/10/30.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
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

import Foundation

/// A structure that contains a geographical coordinate.
public struct LocationInfo {
    
    /// Positive values indicate latitudes north of the equator. Negative values indicate latitudes south of the equator.
    public let latitude: String
    
    /// Measurements are relative to the zero meridian, with positive values extending east of the meridian and negative values extending west of the meridian.
    public let longitude: String
    
    /// The latitude and longitude associated with a location, specified using the WGS 84 reference frame.
    ///
    /// - Parameter latitude: The latitude in degrees.
    /// - Parameter longitude: The longitude in degrees.
    public init(latitude: String, longitude: String) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
