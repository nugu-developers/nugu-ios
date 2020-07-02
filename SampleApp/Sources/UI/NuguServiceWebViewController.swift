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

import NuguServiceKit

final class NuguServiceWebViewController: UIViewController {
    
    @IBOutlet private weak var nuguServiceWebView: NuguServiceWebView!
    
    var initialURLString: String?
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nuguServiceWebView.javascriptDelegate = self
        setCookie()
        nuguServiceWebView.loadUrlString(initialURLString)
    }
}

// MARK: - private

private extension NuguServiceWebViewController {
    func setCookie() {
        let cookie = NuguServiceCookie(
            authToken: UserDefaults.Standard.accessToken ?? "",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            sdkVersion: Bundle(identifier: "com.sktelecom.romaine.NuguClientKit")?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            pocId: SampleApp.clientId ?? "",
            theme: "LIGHT"
        )
        guard let initialURLString = initialURLString,
            let initialUrl = URL(string: initialURLString),
            let scheme = initialUrl.scheme,
            let domain = initialUrl.host else {
                log.debug("setCookie failed!")
                return
        }
        nuguServiceWebView.setNuguServiceCookie(domain: scheme + "://" + domain, nuguServiceCookie: cookie)
    }
}

// MARK: - NuguServiceWebJavascriptDelegate

extension NuguServiceWebViewController: NuguServiceWebJavascriptDelegate {
    func openExternalApp(openExternalAppItem: WebOpenExternalApp) {
        log.debug("openExternalApp : \(openExternalAppItem)")
    }
    
    func openInAppBrowser(url: String) {
        log.debug("openInAppBrowser : \(url)")
    }
}

// MARK: - IBAction

private extension NuguServiceWebViewController {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
