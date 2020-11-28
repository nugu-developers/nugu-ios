//
//  NuguDisplayWebView.swift
//  NuguUIKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/11/27.
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
import WebKit

import NuguAgents

final public class NuguDisplayWebView: UIView {
    // JavaScript Interfaces
    private enum NuguDisplayWebViewInterface: String, CaseIterable {
        case onElementSelected
        case onNuguButtonSelected
        case onChipSelected
        case close
        case onContextChanged
        case onControlResult
    }
    
    public static var displayWebServerAddress = "http://stg-template.aicloud.kr/view"
    
    // Properties
    private var displayWebView: WKWebView?
    private var displayPayload: Data?
    private var displayType: String?
    
    private var focusedItemToken: String?
    private var visibleTokenList: [String]?
    private var controlCompletion: ((Bool) -> Void)?
    
    private var bottomSafeAreaHeight: CGFloat {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return 0 }
        if #available(iOS 11.0, *) {
            return rootViewController.view.safeAreaInsets.bottom
        } else {
            return rootViewController.bottomLayoutGuide.length
        }
    }
    
    // Public Callbacks
    public var onItemSelect: ((_ token: String, _ postBack: [String: AnyHashable]?) -> Void)?
    public var onUserInteraction: (() -> Void)?
    public var onNuguButtonClick: (() -> Void)?
    public var onChipsSelect: ((_ selectedChips: String) -> Void)?
    public var onCloseButtonClick: (() -> Void)?
    public var onTapForStopRecognition: (() -> Void)?
    
    // Override
    public override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
        initializeWebView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromXib()
        initializeWebView()
    }
    
    func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle(for: NuguDisplayWebView.self).loadNibNamed("NuguDisplayWebView", owner: self)?.first as! UIView
        view.frame = bounds
        addSubview(view)
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        onUserInteraction?()
        return super.hitTest(point, with: event)
    }
}

// MARK: - Private (Initialize)

private extension NuguDisplayWebView {
    func initializeWebView() {
        configureWebView()
    }
    
    func configureWebView() {
        let webViewConfiguration = WKWebViewConfiguration()
        
        let userContentController = WKUserContentController()
        for interface in NuguDisplayWebViewInterface.allCases {
            userContentController.add(self, name: interface.rawValue)
        }
        webViewConfiguration.userContentController = userContentController
        
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.javaScriptEnabled = true
        webViewConfiguration.preferences = preferences
        
        let store = WKWebsiteDataStore.default()
        store.removeData(
            ofTypes: Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]),
            modifiedSince: Date(timeIntervalSince1970: 0),
            completionHandler: {}
        )
        webViewConfiguration.websiteDataStore = store
        makeWebView(webViewConfiguration)
    }
    
    func makeWebView(_ configuration: WKWebViewConfiguration) {
        let webViewFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height - bottomSafeAreaHeight)
        let webView = WKWebView(frame: webViewFrame, configuration: configuration)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapForStopRecognition))
        tapGestureRecognizer.delegate = self
        webView.addGestureRecognizer(tapGestureRecognizer)
        webView.allowsLinkPreview = false
        subviews.first?.insertSubview(webView, at: 0)
        displayWebView = webView
    }
    
    @objc func didTapForStopRecognition() {
        onTapForStopRecognition?()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension NuguDisplayWebView: UIGestureRecognizerDelegate {
     public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Public Methods

public extension NuguDisplayWebView {
    func load(displayPayload: Data, displayType: String?, deviceTypeCode: String) {
        self.displayPayload = displayPayload
        self.displayType = displayType
        guard let displayType = self.displayType,
              let payloadData = self.displayPayload,
              let payloadDictionary = try? JSONSerialization.jsonObject(with: payloadData, options: .mutableContainers) as? [String: Any] else { return }
        request(urlString: NuguDisplayWebView.displayWebServerAddress,
                displayType: displayType,
                deviceTypeCode: deviceTypeCode,
                payload: payloadDictionary)
    }
    
    func update(updatePayload: Data) {
        guard let displayingPayloadData = displayPayload,
            let displayingPayloadDictionary = try? JSONSerialization.jsonObject(with: displayingPayloadData, options: []) as? [String: AnyHashable],
            let updatePayloadDictionary = try? JSONSerialization.jsonObject(with: updatePayload, options: []) as? [String: AnyHashable] else {
                return
        }
        let mergedPayloadDictionary = displayingPayloadDictionary.merged(with: updatePayloadDictionary)
        guard let mergedPayloadData = try? JSONSerialization.data(withJSONObject: mergedPayloadDictionary, options: []) else { return }
        displayPayload = mergedPayloadData
    }
    
    func scroll(direction: DisplayControlPayload.Direction, completion: @escaping (Bool) -> Void) {
        self.control(type: "scroll", direction: direction) { (result) in
            completion(result)
        }
    }
    
    func requestContext(completion: @escaping (DisplayContext) -> Void) {
        completion(DisplayContext(focusedItemToken: focusedItemToken, visibleTokenList: visibleTokenList))
    }
}

// MARK: - Private (request)

private extension NuguDisplayWebView {
    func getQueryString(params: [String: Any]) -> String {
        var url = URLComponents()
        url.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value as? String) }
        return url.percentEncodedQuery ?? ""
    }
    
    func request(urlString: String, displayType: String, deviceTypeCode: String, payload: [String: Any]) {
        var displayRequestBodyParam = [String: String]()
        displayRequestBodyParam["device_type_code"] = deviceTypeCode
        
        var dataParam = payload
        let type = displayType.contains(".") ? displayType : "Display.\(displayType)"
        dataParam["type"] = type
        if let jsonData = try? JSONSerialization.data(withJSONObject: dataParam, options: []),
            let jsonStr = String(data: jsonData, encoding: .utf8) {
            displayRequestBodyParam["data"] = jsonStr
        }
        
        guard let url = URL(string: urlString) else { return }
        var displayRequest = URLRequest(url: url)
        
        let queryString = getQueryString(params: displayRequestBodyParam)
        displayRequest.httpBody = queryString.data(using: .utf8)
        
        displayRequest.httpMethod = "POST"
        displayRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
  
        displayWebView?.load(displayRequest)
    }
}

// MARK: - Private (javascript handler)

private extension NuguDisplayWebView {
    func control(type: String, direction: DisplayControlPayload.Direction, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.controlCompletion = completion
            self?.displayWebView?.evaluateJavaScript("control('\(type)', '\(direction.rawValue)')", completionHandler: { (result, error) in
                print("++++ control('\(type)', '\(direction.rawValue)') \(String(describing: result)) \(String(describing: error)) ++++")
            })
        }
    }
}

// MARK: - Private (IBActions)

private extension NuguDisplayWebView {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
}

// MARK: - WKScriptMessageHandler

extension NuguDisplayWebView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("userContentController \(message.name), \(message.body)")
        switch NuguDisplayWebViewInterface(rawValue: message.name) {
        case .onContextChanged:
            if let body = message.body as? [String: Any] {
                if let focusedItemToken = body["focusedItemToken"] as? String {
                    self.focusedItemToken = focusedItemToken
                }
                if let visibleTokenList = body["visibleTokenList"] as? [String] {
                    self.visibleTokenList = visibleTokenList
                }
            }
        case .onControlResult:
            if let body = message.body as? [String: Any] {
                if let result = body["result"] as? String {
                    self.controlCompletion?(result == "succeeded")
                    self.controlCompletion = nil
                }
            }
        case .close:
            if let onCloseButtonClick = self.onCloseButtonClick {
                DispatchQueue.main.async {
                    onCloseButtonClick()
                }
            }
        case .onElementSelected:
            if let token = message.body as? String, let onItemSelect = self.onItemSelect {
                DispatchQueue.main.async {
                    onItemSelect(token, nil)
                }
            }
        case .onNuguButtonSelected:
            if let onNuguButtonClick = self.onNuguButtonClick {
                DispatchQueue.main.async {
                    onNuguButtonClick()
                }
            }
        case .onChipSelected:
            if let chips = message.body as? String, let onChipsSelect = self.onChipsSelect {
                DispatchQueue.main.async {
                    onChipsSelect(chips)
                }
            }
        default: break
        }
    }
}
