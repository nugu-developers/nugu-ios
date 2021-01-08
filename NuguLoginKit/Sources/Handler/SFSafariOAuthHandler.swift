//
//  SFSafariOAuthHandler.swift
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

import UIKit
import SafariServices

@available(iOS 9.0, *)
class SFSafariOAuthHandler: NSObject, OAuthHandler {
    var currentState: String?
    
    var safariViewController: SFSafariViewController? {
        didSet {
            safariViewController?.delegate = self
        }
    }
    
    func handle(_ url: URL, callbackURLScheme: String?, from parentViewController: UIViewController?) {
        let tidSafariViewController = SFSafariViewController(url: url)
        self.safariViewController = tidSafariViewController
        
        parentViewController?.present(tidSafariViewController, animated: true)
    }
    
    func makeState() -> String {
        let state = UUID().uuidString
        currentState = state
        
        return state
    }
    
    func clear() {
        DispatchQueue.main.async { [ weak self] in
            self?.safariViewController?.dismiss(animated: true, completion: { [weak self] in
                self?.currentState = nil
                self?.safariViewController = nil
            })
        }
    }
}

// MARK: - SFSafariViewControllerDelegate

extension SFSafariOAuthHandler: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        NotificationCenter.default.post(name: .authorization, object: nil, userInfo: ["error": NuguLoginKitError.cancelled])
    }
}
