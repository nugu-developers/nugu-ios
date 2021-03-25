//
//  VoiceChromePresenter.swift
//  NuguClientKit
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/11/18.
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

import Foundation
import UIKit

import NuguAgents
import NuguUIKit
import NuguUtils

/// <#Description#>
public class VoiceChromePresenter {
    private let nuguVoiceChrome: NuguVoiceChrome
    
    private weak var nuguClient: NuguClient?
    private weak var viewController: UIViewController?
    private weak var superView: UIView?
    private var targetView: UIView? {
        superView ?? viewController?.view
    }
    
    private var asrState: ASRState = .idle
    private var isMultiturn: Bool = false
    private var voiceChromeDismissWorkItem: DispatchWorkItem?
    
    /// <#Description#>
    public weak var delegate: VoiceChromePresenterDelegate?
    /// <#Description#>
    public var isHidden = true
    
    /// <#Description#>
    /// - Parameters:
    ///   - superView: <#superView description#>
    ///   - nuguVoiceChrome: <#nuguVoiceChrome description#>
    ///   - nuguClient: <#nuguClient description#>
    public convenience init(superView: UIView, nuguVoiceChrome: NuguVoiceChrome, nuguClient: NuguClient) {
        self.init(nuguVoiceChrome: nuguVoiceChrome, nuguClient: nuguClient)
        
        self.superView = superView
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - viewController: <#viewController description#>
    ///   - nuguVoiceChrome: <#nuguVoiceChrome description#>
    ///   - nuguClient: <#nuguClient description#>
    public convenience init(viewController: UIViewController, nuguVoiceChrome: NuguVoiceChrome, nuguClient: NuguClient) {
        self.init(nuguVoiceChrome: nuguVoiceChrome, nuguClient: nuguClient)
        
        self.viewController = viewController
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - nuguVoiceChrome: <#nuguVoiceChrome description#>
    ///   - nuguClient: <#nuguClient description#>
    private init(nuguVoiceChrome: NuguVoiceChrome, nuguClient: NuguClient) {
        self.nuguVoiceChrome = nuguVoiceChrome
        self.nuguClient = nuguClient
        
        nuguClient.dialogStateAggregator.add(delegate: self)
        nuguClient.asrAgent.add(delegate: self)
        nuguClient.interactionControlManager.add(delegate: self)
    }
}

// MARK: - Public (Voice Chrome)

public extension VoiceChromePresenter {
    /// <#Description#>
    /// - Throws: <#description#>
    func presentVoiceChrome() throws {
        guard NetworkReachabilityManager.shared.isReachable else { throw VoiceChromePresenterError.networkUnreachable }
        log.debug("")
        
        voiceChromeDismissWorkItem?.cancel()
        nuguVoiceChrome.removeFromSuperview()
        nuguVoiceChrome.changeState(state: .listeningPassive)
        if nuguClient?.dialogStateAggregator.sessionActivated == true {
            nuguVoiceChrome.setRecognizedText(text: nil)
        }
        
        try showVoiceChrome()
    }
    
    /// <#Description#>
    func dismissVoiceChrome() {
        log.debug("")
        delegate?.voiceChromeWillHide()
        
        isHidden = true
        voiceChromeDismissWorkItem?.cancel()

        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: 0)
        }, completion: { [weak self] _ in
            self?.nuguVoiceChrome.removeFromSuperview()
        })
    }
}

// MARK: - Private

private extension VoiceChromePresenter {
    func showVoiceChrome() throws {
        log.debug("")
        guard let view = targetView else { throw VoiceChromePresenterError.superViewNotExsit }
        guard isHidden == true else { throw VoiceChromePresenterError.alreadyShown }
        
        delegate?.voiceChromeWillShow()
        
        isHidden = false
        
        let showAnimation = {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: -self.nuguVoiceChrome.bounds.height)
            }
        }
        
        if view.subviews.contains(nuguVoiceChrome) == false {
            nuguVoiceChrome.frame = CGRect(x: 0, y: view.frame.size.height, width: view.frame.size.width, height: NuguVoiceChrome.recommendedHeight + SafeAreaUtil.bottomSafeAreaHeight)
            view.addSubview(nuguVoiceChrome)
        }
        showAnimation()
    }
    
    func setChipsButton(actionList: [(text: String, token: String?)], normalList: [(text: String, token: String?)]) {
        var chipsButtonList = [NuguChipsButton.NuguChipsButtonType]()
        let actionButtonList = actionList.map { NuguChipsButton.NuguChipsButtonType.action(text: $0.text, token: $0.token) }
        chipsButtonList.append(contentsOf: actionButtonList)
        let normalButtonList = normalList.map { NuguChipsButton.NuguChipsButtonType.normal(text: $0.text, token: $0.token) }
        chipsButtonList.append(contentsOf: normalButtonList)
        nuguVoiceChrome.setChipsData(chipsData: chipsButtonList)
    }
    
    func disableIdleTimer() {
        guard UIApplication.shared.isIdleTimerDisabled == false else { return }
        guard delegate?.voiceChromeShouldDisableIdleTimer() != false else { return }
        
        UIApplication.shared.isIdleTimerDisabled = true
        log.debug("Disable idle timer")
    }
    
    func enableIdleTimer() {
        guard UIApplication.shared.isIdleTimerDisabled == true else { return }
        guard isMultiturn == false, asrState == .idle else { return }
        guard delegate?.voiceChromeShouldEnableIdleTimer() != false else { return }
        
        UIApplication.shared.isIdleTimerDisabled = false
        log.debug("Enable idle timer")
    }
}

// MARK: - DialogStateDelegate

/// :nodoc:
extension VoiceChromePresenter: DialogStateDelegate {
    public func dialogStateDidChange(_ state: DialogState, isMultiturn: Bool, chips: [ChipsAgentItem.Chip]?, sessionActivated: Bool) {
        log.debug("\(state) \(isMultiturn), \(chips.debugDescription)")
        switch state {
        case .idle:
            voiceChromeDismissWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.dismissVoiceChrome()
            })
            guard let voiceChromeDismissWorkItem = voiceChromeDismissWorkItem else { break }
            DispatchQueue.main.async(execute: voiceChromeDismissWorkItem)
        case .speaking:
            voiceChromeDismissWorkItem?.cancel()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard isMultiturn == true else {
                    self.dismissVoiceChrome()
                    return
                }
                // If voice chrome is not showing or dismissing in speaking state, voice chrome should be presented
                try? self.showVoiceChrome()
                self.nuguVoiceChrome.changeState(state: .speaking)
                if let chips = chips {
                    let actionList = chips.filter { $0.type == .action }.map { ($0.text, $0.token) }
                    let normalList = chips.filter { $0.type == .general }.map { ($0.text, $0.token) }
                    self.setChipsButton(actionList: actionList, normalList: normalList)
                }
            }
        case .listening:
            voiceChromeDismissWorkItem?.cancel()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // If voice chrome is not showing or dismissing in listening state, voice chrome should be presented
                try? self.showVoiceChrome()
                if isMultiturn || sessionActivated {
                    if self.nuguVoiceChrome.currentState != .listeningPassive {
                        self.nuguVoiceChrome.changeState(state: .listeningPassive)
                    }
                    self.nuguVoiceChrome.setRecognizedText(text: nil)
                }
                if let chips = chips {
                    let actionList = chips.filter { $0.type == .action }.map { ($0.text, $0.token) }
                    let normalList = chips.filter { $0.type == .general }.map { ($0.text, $0.token) }
                    self.setChipsButton(actionList: actionList, normalList: normalList)
                }
            }
        case .recognizing:
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.changeState(state: .listeningActive)
            }
        case .thinking:
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.changeState(state: .processing)
            }
        }
    }
}

// MARK: - AutomaticSpeechRecognitionDelegate

/// :nodoc:
extension VoiceChromePresenter: ASRAgentDelegate {
    public func asrAgentDidChange(state: ASRState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.asrState = state
            switch state {
            case .idle:
                self.enableIdleTimer()
            default:
                self.disableIdleTimer()
            }
        }
    }
    
    public func asrAgentDidReceive(result: ASRResult, dialogRequestId: String) {
        switch result {
        case .complete(let text, _):
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.setRecognizedText(text: text)
            }
        case .partial(let text, _):
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.setRecognizedText(text: text)
            }
        case .error(let error, _):
            DispatchQueue.main.async { [weak self] in
                switch error {
                case ASRError.listenFailed:
                    self?.nuguVoiceChrome.changeState(state: .speakingError)
                default:
                    break
                }
            }
        default: break
        }
    }
}

// MARK: - InteractionControlDelegate

/// :nodoc:
extension VoiceChromePresenter: InteractionControlDelegate {
    public func interactionControlDidChange(isMultiturn: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isMultiturn = isMultiturn
            if isMultiturn {
                self.disableIdleTimer()
            } else {
                self.enableIdleTimer()
            }
        }
    }
}
