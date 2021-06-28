//
//  UserInterfaceUtil.swift
//  NuguUtils
//
//  Created by jin kim on 2021/06/02.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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

import UIKit

public struct UserInterfaceUtil {
    public static var style: SystemUserInterfaceStyle {
        if #available(iOS 12.0, *) {
            guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return .unspecified }
            return SystemUserInterfaceStyle(rawValue: rootViewController.traitCollection.userInterfaceStyle.rawValue) ?? .unspecified
        } else {
            return .light
        }
    }
    
    public enum SystemUserInterfaceStyle: Int {
        case unspecified = 0
        case light = 1
        case dark = 2
    }
}
