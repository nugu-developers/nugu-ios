//
//  NuguServiceWebView.swift
//  NuguServiceKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/06/15.
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
import WebKit

import NuguUtils

/// <#Description#>
final public class NuguServiceWebView: WKWebView {
    
    /// Domain for NuguServiceWebView
    public static var domain = "https://webview.sktnugu.com"
    
    private enum MethodType: String, CaseIterable {
        case openExternalApp
        case openInAppBrowser
        case closeWindow
        case requestActiveRoutine
    }
    
    // MARK: Member Variables
    
    /// <#Description#>
    public weak var javascriptDelegate: NuguServiceWebJavascriptDelegate?
    private let scriptMessageName = "NuguWebCommonHandler"
    
    // MARK: Initialize
    
    required init?(coder: NSCoder) {
        let webViewConfiguration = WKWebViewConfiguration()

        // UserController
        let userContentController = WKUserContentController()
        
        // Preference
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        webViewConfiguration.preferences = preferences
        webViewConfiguration.userContentController = userContentController
                
        super.init(frame: .zero, configuration: webViewConfiguration)
        translatesAutoresizingMaskIntoConstraints = false
        
        userContentController.add(WeakScriptMessageHandler(delegate: self), name: scriptMessageName)
    }
    
    deinit {
        configuration.userContentController.removeScriptMessageHandler(forName: scriptMessageName)
    }
}

public extension NuguServiceWebView {
    func onRoutineStatusChanged(token: String, status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.evaluateJavaScript("onRoutineStatusChanged('\(token)', '\(status)')", completionHandler: { (result, error) in
                log.debug("onRoutineStatusChanged('\(token)', '\(status)') \(String(describing: result)) \(String(describing: error))")
            })
        }
    }
}

// MARK: - WKScriptMessageHandler

/// :nodoc:
extension NuguServiceWebView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        log.debug(message)
        guard let jsonDictionary = (message.body as? [String: Any]),
            let methodName = jsonDictionary["method"] as? String,
            let methodType = MethodType(rawValue: methodName) else { return }
        switch methodType {
        case .openExternalApp:
            guard let body = jsonDictionary["body"],
            let bodyData = try? JSONSerialization.data(withJSONObject: body, options: []),
            let openExternalAppItem = try? JSONDecoder().decode(WebOpenExternalApp.self, from: bodyData) else { return }
            javascriptDelegate?.openExternalApp(openExternalAppItem: openExternalAppItem)
        case .openInAppBrowser:
            guard let body = jsonDictionary["body"] as? [String: AnyHashable],
                  let url = body["url"] as? String else { return }    
            javascriptDelegate?.openInAppBrowser(url: url)
        case .closeWindow:
            if let body = jsonDictionary["body"] as? [String: AnyHashable],
               let reason = body["reason"] as? String {
                javascriptDelegate?.closeWindow(reason: reason)
            } else {
                javascriptDelegate?.closeWindow(reason: nil)
            }
        case .requestActiveRoutine:
            javascriptDelegate?.requestActiveRoutine()
        }
    }
}

// MARK: - Cookie Setting

public extension NuguServiceWebView {    
    /// <#Description#>
    /// - Parameter cookie: custom dictionary for user specific cookie setting
    func setCookie(_ cookie: [String: Any]) {        
        let script = cookie
            .map { (element) -> HTTPCookie? in
                let cookieProperties = [
                    HTTPCookiePropertyKey.name: element.key,
                    HTTPCookiePropertyKey.value: element.value,
                    HTTPCookiePropertyKey.domain: NuguServiceWebView.domain,
                    HTTPCookiePropertyKey.path: "/"
                ]
                return HTTPCookie(properties: cookieProperties)
        }
        .compactMap({ $0 })
        .stringValue
        
        let cookieScript = WKUserScript(source: script,
                                        injectionTime: .atDocumentStart,
                                        forMainFrameOnly: false)
        configuration.userContentController.addUserScript(cookieScript)
    }
}

// MARK: - URL Request

public extension NuguServiceWebView {
    func loadUrlString(_ urlString: String?, with queries: [URLQueryItem]? = nil) {
        guard let urlString = urlString,
        let url = URL(string: urlString) else { return }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queries = queries, queries.count > 0 {
            if urlComponents?.queryItems == nil {
                urlComponents?.queryItems = queries
            } else {
                urlComponents?.queryItems?.append(contentsOf: queries)
            }
        }
        guard let urlWithQueries = urlComponents?.url else { return }
        let urlRequest = URLRequest(url: urlWithQueries,
                                    cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 30)
        load(urlRequest)
    }
}
