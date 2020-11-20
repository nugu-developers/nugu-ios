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
import NuguClientKit

final class NuguServiceWebViewController: UIViewController {
    
    @IBOutlet private weak var nuguServiceWebView: NuguServiceWebView!
    
    var initialURLString: String?
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nuguServiceWebView.javascriptDelegate = self
        setCookie()
        nuguServiceWebView.loadUrlString(initialURLString)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshAfterOauth),
            name: .oauthRefresh,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - @objc (oauth_refresh)

private extension NuguServiceWebViewController {
    @objc func refreshAfterOauth() {
        presentedViewController?.dismiss(animated: true, completion: nil)
        nuguServiceWebView.reload()
    }
}

// MARK: - private

private extension NuguServiceWebViewController {
    func setCookie() {
        guard let configuration = ConfigurationStore.shared.configuration else { return }
        
        let cookie = NuguServiceCookie(
            authToken: "Bearer \(UserDefaults.Standard.accessToken ?? "")",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            pocId: configuration.pocId, // Put your own pocId
            theme: "LIGHT",
            oauthRedirectUri: configuration.serviceWebRedirectUri
        )
        nuguServiceWebView.setNuguServiceCookie(nuguServiceCookie: cookie)
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
    
    func closeWindow(reason: String) {
        log.debug("closeWindow : \(reason)")
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
