//
//  NuguThemeController.swift
//  NuguClientKit
//
//  Created by jin kim on 2021/05/27.
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

import Foundation

import NuguUtils

public class NuguThemeController: NSObject, TypedNotifyable {
    private let notificationCenter = NotificationCenter.default
    
    public var theme: NuguTheme = UserInterfaceUtil.style == .dark ? .dark : .light {
        didSet {
            log.info("NuguTheme changed to \(theme)")
            let typedNotification = NuguClientNotification.NuguThemeState.Theme(theme: theme)
            notificationCenter.post(name: .nuguThemeDidChange, object: self, userInfo: typedNotification.dictionary)
        }
    }
}

// MARK: - Observers

extension Notification.Name {
    static let nuguThemeDidChange = Notification.Name("com.sktelecom.romaine.notification.name.nugu_theme_did_change")
}

public extension NuguClientNotification {
    enum NuguThemeState {
        struct Theme: TypedNotification {
            public static let name: Notification.Name = .nuguThemeDidChange
            public let theme: NuguClientKit.NuguTheme
            
            public static func make(from: [String: Any]) -> Theme? {
                guard let theme = from["theme"] as? NuguClientKit.NuguTheme else { return nil }
                return Theme(theme: theme)
            }
        }
    }
}
