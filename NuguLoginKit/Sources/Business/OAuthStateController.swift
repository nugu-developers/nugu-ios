//
//  OAuthStateController.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 27/09/2019.
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
import SafariServices

final class OAuthStateController: NSObject {
    var currentState: String?
    var safariViewController: SFSafariViewController? {
        didSet {
            safariViewController?.delegate = self
        }
    }
    var completionHandler: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?
    
    @discardableResult
    func makeState() -> String {
        let generatedState = UUID().uuidString
        currentState = generatedState
        
        return generatedState
    }
    
    func clearState() {
        currentState = nil
        completionHandler = nil
        safariViewController = nil
    }
    
    func presentSafariViewController(url: URL, from parentViewController: UIViewController) {
        let loginSafariViewController = SFSafariViewController(url: url)
        self.safariViewController = loginSafariViewController
        
        parentViewController.present(loginSafariViewController, animated: true)
    }
    
    func dismissSafariViewController(completion: (() -> Void)? = nil) {
        self.safariViewController?.dismiss(animated: true, completion: completion)
    }
}

// MARK: - SFSafariViewControllerDelegate

extension OAuthStateController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        completionHandler?(.failure(NuguLoginKitError.didFinishSafariViewController))
        clearState()
    }
}
