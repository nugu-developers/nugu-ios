//
//  NuguServiceWebViewController.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/07/02.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

import NuguServiceKit

final class NuguServiceWebViewController: UIViewController {
    var initialURLString: String?
    
    // MARK: Properties
    
    @IBOutlet private weak var nuguServiceWebView: NuguServiceWebView!
    
    // MARK: Observers
    
    private var authObserver: Any?
    
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nuguServiceWebView.javascriptDelegate = self
        nuguServiceWebView.setNuguServiceCookie(deviceUniqueId: NuguCentralManager.shared.oauthClient.deviceUniqueId)
        nuguServiceWebView.loadUrlString(initialURLString)
        
        authObserver = NotificationCenter.default.addObserver(forName: .oauthRefresh, object: nil, queue: .main, using: { [weak self] _ in
            self?.presentedViewController?.dismiss(animated: true, completion: nil)
            self?.nuguServiceWebView.reload()
        })
    }
    
    // MARK: Deinitialize
    
    deinit {
        if let authObserver = authObserver {
            NotificationCenter.default.removeObserver(authObserver)
            self.authObserver = nil
        }
    }
}

// MARK: - NuguServiceWebJavascriptDelegate

extension NuguServiceWebViewController: NuguServiceWebJavascriptDelegate {
    func openExternalApp(openExternalAppItem: WebOpenExternalApp) {
        log.debug("openExternalApp : \(openExternalAppItem)")
        if let appSchemeUrl = URL(string: openExternalAppItem.scheme ?? ""),
            UIApplication.shared.canOpenURL(appSchemeUrl) == true {
            UIApplication.shared.open(appSchemeUrl, options: [:], completionHandler: nil)
            return
        }
        if let appId = openExternalAppItem.appId,
            let appStoreUrl = URL(string: "https://itunes.apple.com/app/" + appId + "?mt=8"),
            UIApplication.shared.canOpenURL(appStoreUrl) == true {
            UIApplication.shared.open(appStoreUrl, options: [:], completionHandler: nil)
        }
    }
    
    func openInAppBrowser(url: String) {
        log.debug("openInAppBrowser : \(url)")
        present(SFSafariViewController(url: URL(string: url)!), animated: true, completion: nil)
    }
    
    func closeWindow(reason: String?) {
        log.debug("closeWindow : \(reason ?? "nil")")
        if reason == "WITHDRAWN_USER" {
            navigationController?.dismiss(animated: true, completion: {
                NuguCentralManager.shared.clearSampleApp()
            })
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - IBAction

private extension NuguServiceWebViewController {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
