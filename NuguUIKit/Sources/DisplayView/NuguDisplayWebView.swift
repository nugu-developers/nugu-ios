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
import NuguUtils

/// <#Description#>
final public class NuguDisplayWebView: UIView {
    // JavaScript Interfaces
    private enum NuguDisplayWebViewInterface: String, CaseIterable {
        case onButtonEvent
        case onNuguButtonSelected
        case onChipSelected
        case close
        case onContextChanged
        case onControlResult
    }
    
    public static var displayWebServerAddress = "http://template.aicloud.kr/view"
    public static var deviceTypeCode: String?
    
    public var displayWebView: WKWebView?
    public private(set) var templateId: String?
    public private(set) var token: String?
    
    // Private Properties
    private var displayPayload: Data?
    private var displayType: String?
    private var deviceTypeCode: String?
    private var clientInfo: [String: String]?
    
    private let darkBackgroundColor: UIColor = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    private let lightBackgroundColor: UIColor = UIColor(red: 248.0/255.0, green: 248.0/255.0, blue: 248.0/255.0, alpha: 1.0)
    
    private var focusedItemToken: String?
    private var visibleTokenList: [String]?
    private var controlCompletion: ((Bool) -> Void)?
        
    // Public Callbacks
    public var onItemSelect: ((_ token: String, _ postBack: [String: AnyHashable]?) -> Void)?
    public var onTextInput: ((_ text: String, _ playServiceId: String?) -> Void)?
    public var onEvent: ((_ templateId: String, _ type: String, _ data: [String: AnyHashable]) -> Void)?
    public var onControl: ((_ type: String) -> Void)?
    public var onUserInteraction: (() -> Void)?
    public var onNuguButtonClick: (() -> Void)?
    public var onChipsSelect: ((_ selectedChips: String) -> Void)?
    public var onTapForStopRecognition: (() -> Void)?
    public var onClose: (() -> Void)?
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var safeAreaCoverView: UIView!
    
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
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        // swiftlint:disable force_cast
        let view = Bundle(for: NuguDisplayWebView.self).loadNibNamed("NuguDisplayWebView", owner: self)?.first as! UIView
        #else
        let view = Bundle.module.loadNibNamed("NuguDisplayWebView", owner: self)?.first as! UIView
        #endif
        // swiftlint:enable force_cast
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
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
            userContentController.add(WeakScriptMessageHandler(delegate: self), name: interface.rawValue)
        }
        webViewConfiguration.userContentController = userContentController
        
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.javaScriptEnabled = true
        webViewConfiguration.preferences = preferences
        
        makeWebView(webViewConfiguration)
    }
    
    func makeWebView(_ configuration: WKWebViewConfiguration) {
        let webView = WKWebView(frame: CGRect(), configuration: configuration)
        webView.isOpaque = false
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapForStopRecognition))
        tapGestureRecognizer.delegate = self
        webView.addGestureRecognizer(tapGestureRecognizer)
        webView.allowsLinkPreview = false
        subviews.first?.insertSubview(webView, at: 0)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -SafeAreaUtil.bottomSafeAreaHeight).isActive = true
        displayWebView = webView
    }
    
    func updateTheme() {
        DispatchQueue.main.async { [weak self] in
            if let themeInfo = self?.clientInfo?["theme"] {
                switch themeInfo {
                case "dark":
                    self?.containerView.backgroundColor = self?.darkBackgroundColor
                    self?.safeAreaCoverView.backgroundColor = self?.darkBackgroundColor
                    self?.displayWebView?.scrollView.backgroundColor = self?.darkBackgroundColor
                case "light":
                    self?.containerView.backgroundColor = self?.lightBackgroundColor
                    self?.safeAreaCoverView.backgroundColor = self?.lightBackgroundColor
                    self?.displayWebView?.scrollView.backgroundColor = self?.lightBackgroundColor
                default: break
                }
            } else {
                switch UserInterfaceUtil.style {
                case .dark:
                    self?.containerView.backgroundColor = self?.darkBackgroundColor
                    self?.safeAreaCoverView.backgroundColor = self?.darkBackgroundColor
                    self?.displayWebView?.scrollView.backgroundColor = self?.darkBackgroundColor
                case .light:
                    self?.containerView.backgroundColor = self?.lightBackgroundColor
                    self?.safeAreaCoverView.backgroundColor = self?.lightBackgroundColor
                    self?.displayWebView?.scrollView.backgroundColor = self?.lightBackgroundColor
                default: break
                }
            }
        }
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
    func load(templateId: String, token: String?, dialogRequestId: String, displayPayload: Data, displayType: String?, clientInfo: [String: String]? = nil) {
        self.templateId = templateId
        if token != nil {
            self.token = token
        }
        self.displayPayload = displayPayload
        self.displayType = displayType
        self.clientInfo = clientInfo
        updateTheme()
        guard let displayType = self.displayType,
              let payloadData = self.displayPayload,
              let payloadDictionary = try? JSONSerialization.jsonObject(with: payloadData, options: .mutableContainers) as? [String: Any] else { return }
        request(dialogRequestId: dialogRequestId,
                urlString: NuguDisplayWebView.displayWebServerAddress,
                displayType: displayType,
                payload: payloadDictionary,
                clientInfo: clientInfo)
    }
    
    func update(templateId: String, dialogRequestId: String, updatePayload: Data) {
        guard let displayingPayloadData = displayPayload,
            let displayingPayloadDictionary = try? JSONSerialization.jsonObject(with: displayingPayloadData, options: []) as? [String: AnyHashable],
            let updatePayloadDictionary = try? JSONSerialization.jsonObject(with: updatePayload, options: []) as? [String: AnyHashable] else {
                return
        }
        let mergedPayloadDictionary = displayingPayloadDictionary.merged(with: updatePayloadDictionary)
        guard let mergedPayloadData = try? JSONSerialization.data(withJSONObject: mergedPayloadDictionary, options: []) else { return }
        displayPayload = mergedPayloadData
        load(templateId: templateId, token: nil, dialogRequestId: dialogRequestId, displayPayload: mergedPayloadData, displayType: displayType, clientInfo: clientInfo)
    }
    
    func scroll(direction: DisplayControlPayload.Direction, completion: @escaping (Bool) -> Void) {
        self.control(type: "scroll", direction: direction) { (result) in
            completion(result)
        }
    }
    
    func requestContext(completion: @escaping (DisplayContext) -> Void) {
        completion(DisplayContext(focusedItemToken: focusedItemToken, visibleTokenList: visibleTokenList))
    }
    
    func onClientInfoChanged(newClientInfo: [String: String]? = nil) {
        if let newClientInfo = newClientInfo {
            clientInfo?.merge(newClientInfo)
        }
        var defaultClientInfo = [String: String]()
        defaultClientInfo["nuguSdkVersion"] = Bundle(for: NuguDisplayWebView.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        defaultClientInfo["osType"] = "IOS"
        if let clientInfo = clientInfo {
            defaultClientInfo.merge(clientInfo)
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: defaultClientInfo, options: []),
            let jsonStr = String(data: jsonData, encoding: .utf8) else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.updateTheme()
            self?.displayWebView?.evaluateJavaScript("nativeEventListener.onClientInfoChanged('\(jsonStr)')", completionHandler: { (result, error) in
                log.debug("nativeEventListener.onClientInfoChanged(\(jsonStr)) \(String(describing: result)) \(String(describing: error))")
            })
        }
    }
}

// MARK: - Private (request)

private extension NuguDisplayWebView {
    func getQueryString(params: [String: Any]) -> String {
        var url = URLComponents()
        url.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value as? String) }
        let plusExcludedCharacterSet = CharacterSet(charactersIn: "/+").inverted
        url.percentEncodedQuery = url.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: plusExcludedCharacterSet)
        return url.percentEncodedQuery ?? ""
    }
    
    func request(dialogRequestId: String, urlString: String, displayType: String, payload: [String: Any], clientInfo: [String: String]?) {
        var displayRequestBodyParam = [String: String]()
        if let deviceTypeCode = NuguDisplayWebView.deviceTypeCode {
            displayRequestBodyParam["device_type_code"] = deviceTypeCode
        } else {
            log.warning("device_type_code is nil")
        }
        
        var dataParam = payload
        let type = displayType.contains(".") ? displayType : "Display.\(displayType)"
        dataParam["type"] = type
        if let jsonData = try? JSONSerialization.data(withJSONObject: dataParam, options: []),
            let jsonStr = String(data: jsonData, encoding: .utf8) {
            displayRequestBodyParam["data"] = jsonStr
        }
        displayRequestBodyParam["dialog_request_id"] = dialogRequestId
        
        var defaultClientInfo = [String: String]()
        defaultClientInfo["nuguSdkVersion"] = Bundle(for: NuguDisplayWebView.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        defaultClientInfo["osType"] = "IOS"
        if let clientInfo = clientInfo {
            defaultClientInfo.merge(clientInfo)
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: defaultClientInfo, options: []),
            let jsonStr = String(data: jsonData, encoding: .utf8) {
            displayRequestBodyParam["client_info"] = jsonStr
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
            self?.displayWebView?.evaluateJavaScript("nativeEventListener.control('\(type)', '\(direction.rawValue)')", completionHandler: { (result, error) in
                log.debug("nativeEventListener.control('\(type)', '\(direction.rawValue)') \(String(describing: result)) \(String(describing: error))")
            })
        }
    }
}

// MARK: - WKScriptMessageHandler

extension NuguDisplayWebView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        log.debug("userContentController \(message.name), \(message.body)")
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
            if let onClose = self.onClose {
                DispatchQueue.main.async {
                    onClose()
                }
            }
        case .onButtonEvent:
            if let body = message.body as? [String: Any],
               let eventType = body["eventType"] as? String,
               let data = body["data"] as? [String: Any] {
                switch eventType {
                case "Display.ElementSelected":
                    if let token = data["token"] as? String,
                       let onItemSelect = self.onItemSelect {
                        DispatchQueue.main.async {
                            onItemSelect(token, data["postback"] as? [String: AnyHashable])
                        }
                    }
                case "Text.TextInput":
                    if let text = data["text"] as? String,
                       let onTextInput = self.onTextInput {
                        DispatchQueue.main.async {
                            onTextInput(text, data["playServiceId"] as? String)
                        }
                    }
                case "EVENT":
                    if let templateId = self.templateId,
                       let type = data["type"] as? String,
                       let eventData = data["data"] as? [String: AnyHashable],
                       let onEvent = self.onEvent {
                        DispatchQueue.main.async {
                            onEvent(templateId, type, eventData)
                        }
                    }
                case "CONTROL":
                    if let type = data["type"] as? String,
                       let onControl = self.onControl {
                        DispatchQueue.main.async {
                            onControl(type)
                        }
                    }
                default: break
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
