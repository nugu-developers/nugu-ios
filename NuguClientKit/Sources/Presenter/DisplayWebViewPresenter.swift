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
    
    private var nuguDisplayWebViews = [NuguDisplayWebView]()
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
    ///   - themeController: Optional controller which can be injected for theme change notification and automatic theme change.
    public convenience init(superView: UIView, nuguClient: NuguClient, clientInfo: [String: String]? = nil, themeController: NuguThemeController? = nil) {
        self.init(nuguClient: nuguClient, clientInfo: clientInfo, themeController: themeController)
        self.superView = superView
    }
    
    /// Initialize with viewController
    /// - Parameters:
    ///   - viewController: Target viewController for NuguDisplayWebView should be added to.
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    ///   - clientInfo: Optional and additional values which can be injected for pre-promised and customized layout.
    ///   - themeController: Optional controller which can be injected for theme change notification and automatic theme change.
    public convenience init(viewController: UIViewController, nuguClient: NuguClient, clientInfo: [String: String]? = nil, themeController: NuguThemeController? = nil) {
        self.init(nuguClient: nuguClient, clientInfo: clientInfo, themeController: themeController)
        self.viewController = viewController
    }
    
    /// Initialize
    /// - Parameters:
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    ///   - clientInfo: Optional and additional values which can be injected for pre-promised and customized layout.
    ///   - themeController: Optional controller which can be injected for theme change notification and automatic theme change.
    private init(nuguClient: NuguClient, clientInfo: [String: String]? = nil, themeController: NuguThemeController? = nil) {
        super.init()
        self.nuguClient = nuguClient
        self.clientInfo = clientInfo
        nuguClient.displayAgent.delegate = self
        if let themeController = themeController {
            addThemeControllerObserver(themeController)
            let newClientInfo = ["theme": themeController.theme.rawValue,
                                 "displayInterfaceVersion": self.nuguClient?.displayAgent.capabilityAgentProperty.version ?? ""]
            self.clientInfo?.merge(newClientInfo)
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
        guard let nuguDisplayWebView = nuguDisplayWebViews.first(where: { $0.templateId == templateId }) else {
            completion(nil)
            return
        }
        nuguDisplayWebView.requestContext(completion: { (displayContext) in
            completion(displayContext)
        })
    }
    
    public func displayAgentShouldRender(template: DisplayTemplate, historyControl: HistoryControl?, completion: @escaping (AnyObject?) -> Void) {
        log.debug("templateId: \(template.templateId), historyControl: \(String(describing: historyControl))")
        DispatchQueue.main.async {  [weak self] in
            if historyControl?.child == true {
                self?.appendChildDisplayView(displayTemplate: template, completion: completion)
            } else {
                self?.addDisplayView(displayTemplate: template, completion: completion)
            }
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
            self?.dismissDisplayView(templateId: templateId)
        }
    }
    
    public func displayAgentShouldMoveFocus(templateId: String, direction: DisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
    
    public func displayAgentShouldScroll(templateId: String, direction: DisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let nuguDisplayWebView = self?.nuguDisplayWebViews.first(where: { $0.templateId == templateId }) else { return }
            nuguDisplayWebView.scroll(direction: direction, completion: completion)
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
        let nuguDisplayWebView = nuguDisplayWebViews.last
        nuguDisplayWebView?.load(
            templateId: displayTemplate.templateId,
            token: displayTemplate.template.token,
            dialogRequestId: displayTemplate.dialogRequestId,
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: self.clientInfo
        )
        nuguDisplayWebView?.onItemSelect = { [weak self] (token, postback) in
            self?.nuguClient?.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        if checkSupportVisibleTokenListOrSupportFocusedItemToken(displayTemplate: displayTemplate) == true {
            addWebViewCompletion = {
                completion(nuguDisplayWebView)
            }
        } else {
            completion(nuguDisplayWebView)
        }
    }
    
    func appendChildDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        let childDisplayWebView = NuguDisplayWebView(frame: CGRect())
        childDisplayWebView.displayWebView?.navigationDelegate = self
        childDisplayWebView.load(
            templateId: displayTemplate.templateId,
            token: displayTemplate.template.token,
            dialogRequestId: displayTemplate.dialogRequestId,
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: self.clientInfo
        )
        childDisplayWebView.onClose = { [weak self] in
            self?.nuguClient?.ttsAgent.stopTTS()
            self?.dismissDisplayView(templateId: displayTemplate.templateId)
        }
        childDisplayWebView.onItemSelect = { [weak self] (token, postback) in
            self?.nuguClient?.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        childDisplayWebView.onTextInput = { [weak self] (text, playServiceId) in
            var requestType: TextAgentRequestType
            if let playServiceId = playServiceId {
                requestType = .specific(playServiceId: playServiceId)
            } else {
                requestType = .dialog
            }
            self?.nuguClient?.textAgent.requestTextInput(text: text, requestType: requestType)
        }
        childDisplayWebView.onEvent = { [weak self] (templateId, type, data) in
            switch type {
            case "Display.TriggerChild":
                self?.nuguClient?.displayAgent.triggerChild(templateId: templateId, data: data)
            default: break
            }
        }
        childDisplayWebView.onControl = { [weak self] (type) in
            switch type {
            case "TEMPLATE_PREVIOUS":
                UIView.animate(
                    withDuration: 0.3,
                    animations: {
                        childDisplayWebView.alpha = 0
                    },
                    completion: { [weak self] _ in
                        self?.nuguDisplayWebViews.removeAll(where: { $0.templateId == childDisplayWebView.templateId })
                        childDisplayWebView.removeFromSuperview()
                        if let templateId = childDisplayWebView.templateId {
                            self?.nuguClient?.displayAgent.displayTemplateViewDidClear(templateId: templateId)
                        }
                    }
                )
            case "TEMPLATE_CLOSEALL":
                self?.nuguClient?.ttsAgent.stopTTS()
                self?.nuguDisplayWebViews.forEach({ displayWebViewToClose in
                    if let templateId = displayWebViewToClose.templateId {
                        self?.nuguClient?.displayAgent.displayTemplateViewDidClear(templateId: templateId)
                    }
                    displayWebViewToClose.removeFromSuperview()
                })
                self?.nuguDisplayWebViews.removeAll()
            default: break
            }
        }
        childDisplayWebView.onUserInteraction = { [weak self] in
            self?.nuguClient?.displayAgent.notifyUserInteraction()
        }
        childDisplayWebView.onTapForStopRecognition = { [weak self] in
            guard [.listening(), .recognizing].contains(self?.nuguClient?.asrAgent.asrState) else { return }
            self?.nuguClient?.asrAgent.stopRecognition()
        }
        childDisplayWebView.onChipsSelect = { [weak self] (selectedChips) in
            self?.nuguClient?.requestTextInput(text: selectedChips, requestType: .dialog)
        }
        childDisplayWebView.onNuguButtonClick = { [weak self] in
            self?.delegate?.onDisplayWebViewNuguButtonClick()
        }
        
        childDisplayWebView.alpha = 0
        guard let targetView = self.targetView else {
            completion(nil)
            return
        }
        if let voiceChrome = targetView.subviews.filter({ $0.isKind(of: NuguVoiceChrome.self) }).first {
            targetView.insertSubview(childDisplayWebView, belowSubview: voiceChrome)
        } else {
            targetView.addSubview(childDisplayWebView)
        }
        childDisplayWebView.translatesAutoresizingMaskIntoConstraints = false
        childDisplayWebView.topAnchor.constraint(equalTo: targetView.topAnchor).isActive = true
        childDisplayWebView.leadingAnchor.constraint(equalTo: targetView.leadingAnchor).isActive = true
        childDisplayWebView.trailingAnchor.constraint(equalTo: targetView.trailingAnchor).isActive = true
        childDisplayWebView.bottomAnchor.constraint(equalTo: targetView.bottomAnchor).isActive = true
        
        targetView.layoutIfNeeded()
        
        if checkSupportVisibleTokenListOrSupportFocusedItemToken(displayTemplate: displayTemplate) == true {
            addWebViewCompletion = {
                completion(childDisplayWebView)
            }
        } else {
            completion(childDisplayWebView)
        }

        UIView.animate(withDuration: 0.3, animations: {
            childDisplayWebView.alpha = 1.0
        }, completion: { [weak self] (_) in
            self?.nuguDisplayWebViews.append(childDisplayWebView)
        })
    }
    
    func addDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        if let targetView = self.targetView,
           let nuguDisplayWebView = self.nuguDisplayWebViews.last,
            targetView.subviews.contains(nuguDisplayWebView) {
            replaceDisplayView(displayTemplate: displayTemplate, completion: completion)
            return
        }
        let nuguDisplayWebView = NuguDisplayWebView(frame: CGRect())
        nuguDisplayWebView.displayWebView?.navigationDelegate = self
        nuguDisplayWebView.load(
            templateId: displayTemplate.templateId,
            token: displayTemplate.template.token,
            dialogRequestId: displayTemplate.dialogRequestId,
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: self.clientInfo
        )
        nuguDisplayWebView.onClose = { [weak self] in
            self?.nuguClient?.ttsAgent.stopTTS()
            self?.dismissDisplayView(templateId: displayTemplate.templateId)
        }
        nuguDisplayWebView.onItemSelect = { [weak self] (token, postback) in
            self?.nuguClient?.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        nuguDisplayWebView.onTextInput = { [weak self] (text, playServiceId) in
            var requestType: TextAgentRequestType
            if let playServiceId = playServiceId {
                requestType = .specific(playServiceId: playServiceId)
            } else {
                requestType = .dialog
            }
            self?.nuguClient?.textAgent.requestTextInput(text: text, requestType: requestType)
        }
        nuguDisplayWebView.onEvent = { [weak self] (templateId, type, data) in
            switch type {
            case "Display.TriggerChild":
                self?.nuguClient?.displayAgent.triggerChild(templateId: templateId, data: data)
            default: break
            }
        }
        nuguDisplayWebView.onControl = { [weak self] (type) in
            switch type {
            case "TEMPLATE_PREVIOUS":
                UIView.animate(
                    withDuration: 0.3,
                    animations: {
                        nuguDisplayWebView.alpha = 0
                    },
                    completion: { [weak self] _ in
                        self?.nuguDisplayWebViews.removeAll(where: { $0.templateId == nuguDisplayWebView.templateId })
                        nuguDisplayWebView.removeFromSuperview()
                        if let templateId = nuguDisplayWebView.templateId {
                            self?.nuguClient?.displayAgent.displayTemplateViewDidClear(templateId: templateId)
                        }
                    }
                )
            case "TEMPLATE_CLOSEALL":
                self?.nuguClient?.ttsAgent.stopTTS()
                self?.nuguDisplayWebViews.forEach({ displayWebViewToClose in
                    if let templateId = displayWebViewToClose.templateId {
                        self?.nuguClient?.displayAgent.displayTemplateViewDidClear(templateId: templateId)
                    }
                    displayWebViewToClose.removeFromSuperview()
                })
                self?.nuguDisplayWebViews.removeAll()
            default: break
            }
        }
        nuguDisplayWebView.onUserInteraction = { [weak self] in
            self?.nuguClient?.displayAgent.notifyUserInteraction()
        }
        nuguDisplayWebView.onTapForStopRecognition = { [weak self] in
            guard [.listening(), .recognizing].contains(self?.nuguClient?.asrAgent.asrState) else { return }
            self?.nuguClient?.asrAgent.stopRecognition()
        }
        nuguDisplayWebView.onChipsSelect = { [weak self] (selectedChips) in
            self?.nuguClient?.requestTextInput(text: selectedChips, requestType: .dialog)
        }
        nuguDisplayWebView.onNuguButtonClick = { [weak self] in
            self?.delegate?.onDisplayWebViewNuguButtonClick()
        }
        
        nuguDisplayWebView.alpha = 0
        guard let targetView = self.targetView else {
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
        
        targetView.layoutIfNeeded()
        
        if checkSupportVisibleTokenListOrSupportFocusedItemToken(displayTemplate: displayTemplate) == true {
            addWebViewCompletion = {
                completion(nuguDisplayWebView)
            }
        } else {
            completion(nuguDisplayWebView)
        }

        UIView.animate(withDuration: 0.3, animations: {
            nuguDisplayWebView.alpha = 1.0
        }, completion: { [weak self] (_) in
            self?.nuguDisplayWebViews.append(nuguDisplayWebView)
        })
    }
    
    func updateDisplayView(displayTemplate: DisplayTemplate) {
        guard let nuguDisplayWebView = nuguDisplayWebViews.first(where: { $0.token == displayTemplate.template.token }) else { return }
        nuguDisplayWebView.update(
            templateId: displayTemplate.templateId,
            dialogRequestId: displayTemplate.dialogRequestId,
            updatePayload: displayTemplate.payload
        )
    }
    
    func dismissDisplayView(templateId: String) {
        guard let nuguDisplayWebView = nuguDisplayWebViews.first(where: { $0.templateId == templateId }) else { return }
        UIView.animate(
            withDuration: 0.3,
            animations: {
                nuguDisplayWebView.alpha = 0
            },
            completion: { [weak self] _ in
                self?.nuguDisplayWebViews.forEach({ displayWebViewToClose in
                    if let templateId = displayWebViewToClose.templateId {
                        self?.nuguClient?.displayAgent.displayTemplateViewDidClear(templateId: templateId)
                    }
                    displayWebViewToClose.removeFromSuperview()
                })
                self?.nuguDisplayWebViews.removeAll()
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
    func addThemeControllerObserver(_ object: NuguThemeController) {
        themeObserver = object.observe(NuguClientNotification.NuguThemeState.Theme.self, queue: nil, using: { [weak self] notification in
            guard let self = self else { return }
            let newClientInfo = ["theme": notification.theme.rawValue]
            self.clientInfo?.merge(newClientInfo)
            DispatchQueue.main.async { [weak self] in
                self?.nuguDisplayWebViews.forEach({ nuguDisplayWebView in
                    nuguDisplayWebView.onClientInfoChanged(newClientInfo: newClientInfo)
                })
            }
        })
    }
}
