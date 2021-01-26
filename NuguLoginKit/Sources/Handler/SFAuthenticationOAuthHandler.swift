//
//  SFAuthenticationOAuthHandler.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 2020/11/21.
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
import SafariServices

@available(iOS, introduced: 11.0, deprecated: 12.0)
class SFAuthenticationOAuthHandler: NSObject, OAuthHandler {
    var currentState: String?
    var authSession: SFAuthenticationSession?
    
    func handle(_ url: URL, callbackURLScheme: String?, from parentViewController: UIViewController?) {
        authSession = SFAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: { (url, error) in
            if let error = error {
                let sessionError = (error as NSError)
                // isCancelled
                if sessionError.domain == SFAuthenticationErrorDomain &&
                    sessionError.code == SFAuthenticationError.canceledLogin.rawValue {
                    NotificationCenter.default.post(name: .authorization, object: nil, userInfo: ["error": NuguLoginKitError.cancelled])
                } else {
                    NotificationCenter.default.post(name: .authorization, object: nil, userInfo: ["error": error])
                }
            } else if let callbackURL = url {
                NotificationCenter.default.post(name: .authorization, object: nil, userInfo: ["url": callbackURL])
            } else {
                return
            }
        })
        
        authSession?.start()
    }
    
    func makeState() -> String {
        let state = UUID().uuidString
        currentState = state
        
        return state
    }
    
    func clear() {
        authSession?.cancel()
        
        currentState = nil
        authSession = nil
    }
}
