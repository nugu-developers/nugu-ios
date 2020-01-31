//
//  NuguWebView.swift
//  SampleApp
//
//  Created by yonghoonKwon on 09/07/2019.
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

import UIKit
import WebKit

final class NuguWebView: WKWebView {
    required init?(coder: NSCoder) {
        let webViewConfiguration = WKWebViewConfiguration()
        
        //UserController
        let userContentController = WKUserContentController()
        
        //Preference
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        webViewConfiguration.preferences = preferences
        webViewConfiguration.userContentController = userContentController
        
        let store = WKWebsiteDataStore.default()
        store.removeData(ofTypes: Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]),
                         modifiedSince: Date(timeIntervalSince1970: 0),
                         completionHandler: {
                            // Do not anything
        })
        webViewConfiguration.websiteDataStore = store
        
        super.init(frame: .zero, configuration: webViewConfiguration)
        translatesAutoresizingMaskIntoConstraints = false
    }
}
