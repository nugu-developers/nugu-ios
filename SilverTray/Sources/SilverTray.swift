//
//  SilverTray.swift
//  SilverTray
//
//  Created by childc on 2020/05/14.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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
import os.log

extension OSLog {
    private static var subsystem = Bundle(for: DataStreamPlayer.self).bundleIdentifier ?? "SilverTray"
    static let audioEngine = OSLog(subsystem: subsystem, category: "STDSP_engine")
    static let player = OSLog(subsystem: subsystem, category: "STDSP_player")
    static let decoder = OSLog(subsystem: subsystem, category: "STDSP_decoder")
}
