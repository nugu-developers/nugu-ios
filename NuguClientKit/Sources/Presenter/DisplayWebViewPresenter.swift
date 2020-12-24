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

import NuguAgents
import NuguUIKit
import NuguCore

/// DisplayWebViewPresenter is a class which helps user for displaying DisplayWebView more easily.
public class DisplayWebViewPresenter {

    public weak var delegate: DisplayWebViewPresenterDelegate?
    
    private var nuguDisplayWebView: NuguDisplayWebView?
    private weak var viewController: UIViewController?
    private weak var superView: UIView?
    private var targetView: UIView? {
        superView ?? viewController?.view
    }
    private var nuguClient: NuguClient?
    private var clientInfo: [String: String]?
    
    /// Initialize with superView
    /// - Parameters:
    ///   - superView: Target view for NuguDisplayWebView should be added to.
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    ///   - clientInfo: Optional and additional values which can be injected for pre-promised and customized layout.
    public convenience init(superView: UIView, nuguClient: NuguClient, clientInfo: [String: String]? = nil) {
        self.init(nuguClient: nuguClient, clientInfo: clientInfo)
        self.superView = superView
    }
    
    /// Initialize with viewController
    /// - Parameters:
    ///   - viewController: Target viewController for NuguDisplayWebView should be added to.
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    ///   - clientInfo: Optional and additional values which can be injected for pre-promised and customized layout.
    public convenience init(viewController: UIViewController, nuguClient: NuguClient, clientInfo: [String: String]? = nil) {
        self.init(nuguClient: nuguClient, clientInfo: clientInfo)
        self.viewController = viewController
    }
    
    /// Initialize
    /// - Parameters:
    ///   - nuguClient: NuguClient instance which should be passed for delegation.
    ///   - clientInfo: Optional and additional values which can be injected for pre-promised and customized layout.
    private init(nuguClient: NuguClient, clientInfo: [String: String]? = nil) {
        self.nuguClient = nuguClient
        self.clientInfo = clientInfo
        nuguClient.displayAgent.delegate = self
    }
}

// MARK: - DisplayAgentDelegate

extension DisplayWebViewPresenter: DisplayAgentDelegate {
    public func displayAgentRequestContext(templateId: String, completion: @escaping (DisplayContext?) -> Void) {
        nuguDisplayWebView?.requestContext(completion: { (displayContext) in
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

private extension DisplayWebViewPresenter {
    func replaceDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        guard let nuguDisplayWebView = self.nuguDisplayWebView else {
            completion(nil)
            return
        }
        nuguDisplayWebView.load(
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: self.clientInfo
        )
        nuguDisplayWebView.onItemSelect = { [weak self] (token, postback) in
            self?.nuguClient?.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
            self?.delegate?.onDisplayWebViewItemSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        completion(nuguDisplayWebView)
    }
    
    func addDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        if let targetView = self.targetView,
           let nuguDisplayWebView = self.nuguDisplayWebView,
            targetView.subviews.contains(nuguDisplayWebView) {
            replaceDisplayView(displayTemplate: displayTemplate, completion: completion)
            return
        }
        nuguDisplayWebView = NuguDisplayWebView(frame: targetView?.frame ?? .zero)
        nuguDisplayWebView?.load(
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: self.clientInfo
        )
        nuguDisplayWebView?.onClose = { [weak self] in
            self?.nuguClient?.ttsAgent.stopTTS()
            self?.dismissDisplayView()
            self?.delegate?.onDisplayWebViewClose()
        }
        nuguDisplayWebView?.onItemSelect = { [weak self] (token, postback) in
            self?.nuguClient?.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
            self?.delegate?.onDisplayWebViewItemSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        nuguDisplayWebView?.onUserInteraction = { [weak self] in
            self?.nuguClient?.displayAgent.notifyUserInteraction()
            self?.delegate?.onDisplayWebViewUserInteraction()
        }
        nuguDisplayWebView?.onTapForStopRecognition = { [weak self] in
            guard [.listening, .recognizing].contains(self?.nuguClient?.asrAgent.asrState) else { return }
            self?.nuguClient?.asrAgent.stopRecognition()
            self?.delegate?.onDisplayWebViewTapForStopRecognition()
        }
        nuguDisplayWebView?.onChipsSelect = { [weak self] (selectedChips) in
            self?.nuguClient?.requestTextInput(text: selectedChips, requestType: .dialog)
            self?.delegate?.onDisplayWebViewChipsSelect(selectedChips: selectedChips)
        }
        nuguDisplayWebView?.onNuguButtonClick = { [weak self] in
            self?.delegate?.onDisplayWebViewNuguButtonClick()
        }
        
        nuguDisplayWebView?.alpha = 0
        guard let nuguDisplayWebView = self.nuguDisplayWebView else {
            completion(nil)
            return
        }
        targetView?.addSubview(nuguDisplayWebView)
        
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "btn_close"), for: .normal)
        closeButton.frame = CGRect(x: nuguDisplayWebView.frame.size.width - 48, y: SafeAreaUtil.topSafeAreaHeight + 16, width: 28.0, height: 28.0)
        closeButton.addTarget(self, action: #selector(self.onDisplayViewCloseButtonDidClick), for: .touchUpInside)
        nuguDisplayWebView.addSubview(closeButton)
        
        completion(nuguDisplayWebView)
        UIView.animate(withDuration: 0.3, animations: {
            nuguDisplayWebView.alpha = 1.0
        }, completion: { [weak self] (_) in
            self?.nuguDisplayWebView = nuguDisplayWebView
        })
    }
    
    @objc func onDisplayViewCloseButtonDidClick() {
        nuguClient?.ttsAgent.stopTTS()
        dismissDisplayView()
        delegate?.onDisplayWebViewClose()
    }
    
    func updateDisplayView(displayTemplate: DisplayTemplate) {
        nuguDisplayWebView?.update(updatePayload: displayTemplate.payload)
    }
    
    func dismissDisplayView() {
        guard let nuguDisplayWebView = self.nuguDisplayWebView else { return }
        UIView.animate(
            withDuration: 0.3,
            animations: {
                nuguDisplayWebView.alpha = 0
            },
            completion: { _ in
                nuguDisplayWebView.removeFromSuperview()
            }
        )
    }
}
