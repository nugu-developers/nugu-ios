//
//  DisplayWebViewPresenter.swift
//  NuguClientKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/12/21.
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

import Foundation
import UIKit
import WebKit

import NuguAgents
import NuguUIKit
import NuguCore
import NuguUtils

/// DisplayWebViewPresenter is a class which helps user for displaying DisplayWebView more easily.
public class DisplayWebViewPresenter: NSObject {

    public weak var delegate: DisplayWebViewPresenterDelegate?
    
    private var nuguDisplayWebView: NuguDisplayWebView?
    private weak var viewController: UIViewController?
    private weak var superView: UIView?
    private var targetView: UIView? {
        superView ?? viewController?.view
    }
    private weak var nuguClient: NuguClient?
    private var clientInfo: [String: String]?
    private var addWebViewCompletion: (() -> Void)?
    private var topSafeAreaAnchor: NSLayoutYAxisAnchor? {
        return self.targetView?.safeAreaLayoutGuide.topAnchor
    }
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var themeObserver: Any?
    
    /// Initialize with superView
    /// - Parameters:
    ///   - superView: Target view for NuguDisplayWebView should be added to.
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    ///   - clientInfo: Optional and additional values which can be injected for pre-promised and customized layout.
    ///   - clientInfo: Optional controller which can be injected for theme change notification and automatic theme change.
    public convenience init(superView: UIView, nuguClient: NuguClient, clientInfo: [String: String]? = nil, themeController: NuguThemeController? = nil) {
        self.init(nuguClient: nuguClient, clientInfo: clientInfo, themeController: themeController)
        self.superView = superView
    }
    
    /// Initialize with viewController
    /// - Parameters:
    ///   - viewController: Target viewController for NuguDisplayWebView should be added to.
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    ///   - clientInfo: Optional and additional values which can be injected for pre-promised and customized layout.
    ///   - clientInfo: Optional controller which can be injected for theme change notification and automatic theme change.
    public convenience init(viewController: UIViewController, nuguClient: NuguClient, clientInfo: [String: String]? = nil, themeController: NuguThemeController? = nil) {
        self.init(nuguClient: nuguClient, clientInfo: clientInfo, themeController: themeController)
        self.viewController = viewController
    }
    
    /// Initialize
    /// - Parameters:
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    ///   - clientInfo: Optional and additional values which can be injected for pre-promised and customized layout.
    ///   - clientInfo: Optional controller which can be injected for theme change notification and automatic theme change.
    private init(nuguClient: NuguClient, clientInfo: [String: String]? = nil, themeController: NuguThemeController? = nil) {
        super.init()
        self.nuguClient = nuguClient
        self.clientInfo = clientInfo
        nuguClient.displayAgent.delegate = self
        if let themeController = themeController {
            addThemeManagerObserver(themeController)
        }
    }
    
    deinit {
        if let themeObserver = themeObserver {
            notificationCenter.removeObserver(themeObserver)
        }
    }
}

// MARK: - DisplayAgentDelegate

extension DisplayWebViewPresenter: DisplayAgentDelegate {
    public func displayAgentRequestContext(templateId: String, completion: @escaping (DisplayContext?) -> Void) {
        guard let nuguDisplayWebView = nuguDisplayWebView  else {
            completion(nil)
            return
        }
        nuguDisplayWebView.requestContext(completion: { (displayContext) in
            completion(displayContext)
        })
    }
    
    public func displayAgentShouldRender(template: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        log.debug("templateId: \(template.templateId)")
        DispatchQueue.main.async {  [weak self] in
            self?.addDisplayView(displayTemplate: template, completion: completion)
        }
    }
    
    public func displayAgentShouldUpdate(templateId: String, template: DisplayTemplate) {
        log.debug("templateId: \(templateId)")
        DispatchQueue.main.async { [weak self] in
            self?.updateDisplayView(displayTemplate: template)
        }
    }
    
    public func displayAgentDidClear(templateId: String) {
        log.debug("templateId: \(templateId)")
        DispatchQueue.main.async { [weak self] in
            self?.dismissDisplayView()
        }
    }
    
    public func displayAgentShouldMoveFocus(templateId: String, direction: DisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
    
    public func displayAgentShouldScroll(templateId: String, direction: DisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.nuguDisplayWebView?.scroll(direction: direction, completion: completion)
        }
    }
}

// MARK: - Private (DisplayView present/dismiss)

private extension DisplayWebViewPresenter {
    func checkSupportVisibleTokenListOrSupportFocusedItemToken(displayTemplate: DisplayTemplate) -> Bool {
        guard let jsonPayload = try? JSONSerialization.jsonObject(with: displayTemplate.payload, options: []) as? [String: Any] else {
            return false
        }
        let supportVisibleTokenList = jsonPayload["supportVisibleTokenList"] as? Bool
        let supportFocusedItemToken = jsonPayload["supportFocusedItemToken"] as? Bool
        return (supportVisibleTokenList == true) || (supportFocusedItemToken == true)
    }
    
    func replaceDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        nuguDisplayWebView?.load(
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: self.clientInfo
        )
        nuguDisplayWebView?.onItemSelect = { [weak self] (token, postback) in
            self?.nuguClient?.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        if checkSupportVisibleTokenListOrSupportFocusedItemToken(displayTemplate: displayTemplate) == true {
            addWebViewCompletion = { [weak self] in
                guard let self = self else { return }
                completion(self.nuguDisplayWebView)
            }
        } else {
            completion(nuguDisplayWebView)
        }
    }
    
    func addDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        if let targetView = self.targetView,
           let nuguDisplayWebView = self.nuguDisplayWebView,
            targetView.subviews.contains(nuguDisplayWebView) {
            replaceDisplayView(displayTemplate: displayTemplate, completion: completion)
            return
        }
        nuguDisplayWebView = NuguDisplayWebView(frame: CGRect())
        nuguDisplayWebView?.displayWebView?.navigationDelegate = self
        nuguDisplayWebView?.load(
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: self.clientInfo
        )
        nuguDisplayWebView?.onClose = { [weak self] in
            self?.nuguClient?.ttsAgent.stopTTS()
            self?.dismissDisplayView()
        }
        nuguDisplayWebView?.onItemSelect = { [weak self] (token, postback) in
            self?.nuguClient?.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        nuguDisplayWebView?.onUserInteraction = { [weak self] in
            self?.nuguClient?.displayAgent.notifyUserInteraction()
        }
        nuguDisplayWebView?.onTapForStopRecognition = { [weak self] in
            guard [.listening, .recognizing].contains(self?.nuguClient?.asrAgent.asrState) else { return }
            self?.nuguClient?.asrAgent.stopRecognition()
        }
        nuguDisplayWebView?.onChipsSelect = { [weak self] (selectedChips) in
            self?.nuguClient?.requestTextInput(text: selectedChips, requestType: .dialog)
        }
        nuguDisplayWebView?.onNuguButtonClick = { [weak self] in
            self?.delegate?.onDisplayWebViewNuguButtonClick()
        }
        
        nuguDisplayWebView?.alpha = 0
        guard let nuguDisplayWebView = self.nuguDisplayWebView, let targetView = self.targetView else {
            completion(nil)
            return
        }
        if let voiceChrome = targetView.subviews.filter({ $0.isKind(of: NuguVoiceChrome.self) }).first {
            targetView.insertSubview(nuguDisplayWebView, belowSubview: voiceChrome)
        } else {
            targetView.addSubview(nuguDisplayWebView)
        }
        nuguDisplayWebView.translatesAutoresizingMaskIntoConstraints = false
        nuguDisplayWebView.topAnchor.constraint(equalTo: targetView.topAnchor).isActive = true
        nuguDisplayWebView.leadingAnchor.constraint(equalTo: targetView.leadingAnchor).isActive = true
        nuguDisplayWebView.trailingAnchor.constraint(equalTo: targetView.trailingAnchor).isActive = true
        nuguDisplayWebView.bottomAnchor.constraint(equalTo: targetView.bottomAnchor).isActive = true
        
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "btn_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.onDisplayViewCloseButtonDidClick), for: .touchUpInside)
        nuguDisplayWebView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: topSafeAreaAnchor ?? targetView.topAnchor, constant: 20).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: -20).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        targetView.layoutIfNeeded()
        
        if checkSupportVisibleTokenListOrSupportFocusedItemToken(displayTemplate: displayTemplate) == true {
            addWebViewCompletion = { [weak self] in
                guard let self = self else { return }
                completion(self.nuguDisplayWebView)
            }
        } else {
            completion(nuguDisplayWebView)
        }

        UIView.animate(withDuration: 0.3, animations: {
            nuguDisplayWebView.alpha = 1.0
        }, completion: { [weak self] (_) in
            self?.nuguDisplayWebView = nuguDisplayWebView
        })
    }
    
    @objc func onDisplayViewCloseButtonDidClick() {
        nuguClient?.ttsAgent.stopTTS()
        dismissDisplayView()
    }
    
    func updateDisplayView(displayTemplate: DisplayTemplate) {
        nuguDisplayWebView?.update(updatePayload: displayTemplate.payload)
    }
    
    func dismissDisplayView() {
        guard nuguDisplayWebView != nil else { return }
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.nuguDisplayWebView?.alpha = 0
            },
            completion: { [weak self] _ in
                self?.nuguDisplayWebView?.removeFromSuperview()
                self?.nuguDisplayWebView = nil
            }
        )
    }
}

// MARK: - WKNavigationDelegate

extension DisplayWebViewPresenter: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        addWebViewCompletion?()
    }
}

// MARK: - Observer

extension DisplayWebViewPresenter {
    func addThemeManagerObserver(_ object: NuguThemeController) {
        themeObserver = object.observe(NuguClientNotification.NuguThemeState.Theme.self, queue: nil, using: { [weak self] notification in
            guard let self = self else { return }
            let newClientInfo = ["theme": notification.theme.rawValue]
            self.clientInfo?.merge(newClientInfo)
            DispatchQueue.main.async { [weak self] in
                self?.nuguDisplayWebView?.onClientInfoChanged(newClientInfo: newClientInfo)
            }
        })
    }
}
