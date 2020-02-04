//
//  WakeUpInfoDelegate.swift
//  NuguAgents
//
//  Created by DCs-OfficeMBP on 19/06/2019.
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

public protocol WakeUpInfoDelegate: class {
    /**
     Nugu server requires Wake Up Voice data when you using KeenSense as a Wake up detector.
     - If you don't use KeenSense, Don't implement this delegate.
     - returns: Wake up data and padding size
     */
    func requestWakeUpInfo() -> (Data, Int)?
}
