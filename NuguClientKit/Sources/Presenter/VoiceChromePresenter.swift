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
import NuguCore

/// `VoiceChromePresenter` is a class which helps user for displaying `NuguVoiceChrome` more easily.
public class VoiceChromePresenter: NSObject {
    private let nuguVoiceChrome: NuguVoiceChrome
    
    private weak var nuguClient: NuguClient?
    private weak var viewController: UIViewController?
    private weak var superView: UIView?
    private var targetView: UIView? {
        superView ?? viewController?.view
    }
    private var asrBeepPlayer: ASRBeepPlayer?
    
    private var asrState: ASRState = .idle
    private var isMultiturn: Bool = false
    private var voiceChromeDismissWorkItem: DispatchWorkItem?
    
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapForStopRecognition))
        tapGestureRecognizer.delegate = self
        
        return tapGestureRecognizer
    }()
    
    public weak var delegate: VoiceChromePresenterDelegate?
    public var isHidden = true {
        didSet {
            if isHidden {
                targetView?.removeGestureRecognizer(tapGestureRecognizer)
            } else {
                targetView?.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }
    
    public var isStartBeepEnabled = true {
        didSet {
            ASRBeepPlayer.isStartBeepEnabled = isStartBeepEnabled
        }
    }
    public var isSuccessBeepEnabled = true {
        didSet {
            ASRBeepPlayer.isSuccessBeepEnabled = isSuccessBeepEnabled
        }
    }
    public var isFailBeepEnabled = true {
        didSet {
            ASRBeepPlayer.isFailBeepEnabled = isFailBeepEnabled
        }
    }
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var interactionControlObserver: Any?
    private var asrStateObserver: Any?
    private var asrResultObserver: Any?
    private var dialogStateObserver: Any?
    
    /// Initialize with superView
    /// - Parameters:
    ///   - superView: Target view for `NuguVoiceChrome` should be added to.
    ///   - nuguVoiceChrome: `NuguVoiceChrome` to be managed by `VoiceChromePresenter`. If nil, it is initiated internally.
    ///   - nuguClient: `NuguClient` instance which should be passed for delegation.
    ///   - asrBeepPlayerResourcesURL: `ASRBeepPlayerResourcesURL` instance for setting custom url path of beep resources
    public convenience init(
        superView: UIView,
        nuguVoiceChrome: NuguVoiceChrome? = nil,
        nuguClient: NuguClient,
        asrBeepPlayerResourcesURL: ASRBeepPlayerResourcesURL = ASRBeepPlayerResourcesURL()
    ) {
        self.init(nuguVoiceChrome: nuguVoiceChrome, nuguClient: nuguClient, asrBeepPlayerResourcesURL: asrBeepPlayerResourcesURL)
        
        self.superView = superView
    }
    
    /// Initialize with superView
    /// - Parameters:
    ///   - viewController: Target `ViewController` for `NuguVoiceChrome` should be added to.
    ///   - nuguVoiceChrome: `NuguVoiceChrome` to be managed by `VoiceChromePresenter`. If nil, it is initiated internally.
    ///   - nuguClient: `NuguClient` instance which should be passed for delegation.
    ///   - asrBeepPlayerResourcesURL: `ASRBeepPlayerResourcesURL` instance for setting custom url path of beep resources
    public convenience init(
        viewController: UIViewController,
        nuguVoiceChrome: NuguVoiceChrome? = nil,
        nuguClient: NuguClient,
        asrBeepPlayerResourcesURL: ASRBeepPlayerResourcesURL = ASRBeepPlayerResourcesURL()
    ) {
        self.init(nuguVoiceChrome: nuguVoiceChrome, nuguClient: nuguClient, asrBeepPlayerResourcesURL: asrBeepPlayerResourcesURL)
        
        self.viewController = viewController
    }
    
    private init(
        nuguVoiceChrome: NuguVoiceChrome?,
        nuguClient: NuguClient,
        asrBeepPlayerResourcesURL: ASRBeepPlayerResourcesURL
    ) {
        self.nuguVoiceChrome = nuguVoiceChrome ?? NuguVoiceChrome(frame: CGRect())
        self.nuguClient = nuguClient
        self.asrBeepPlayer = ASRBeepPlayer(focusManager: nuguClient.focusManager, resourcesUrl: asrBeepPlayerResourcesURL)
        
        super.init()
        
        // Observers
        addInteractionControlObserver(nuguClient.interactionControlManager)
        addAsrAgentObserver(nuguClient.asrAgent)
        addDialogStateObserver(nuguClient.dialogStateAggregator)
    }
    
    deinit {
        if let interactionControlObserver = interactionControlObserver {
            notificationCenter.removeObserver(interactionControlObserver)
        }
        
        if let asrStateObserver = asrStateObserver {
            notificationCenter.removeObserver(asrStateObserver)
        }
        
        if let asrResultObserver = asrResultObserver {
            notificationCenter.removeObserver(asrResultObserver)
        }
        
        if let dialogStateObserver = dialogStateObserver {
            notificationCenter.removeObserver(dialogStateObserver)
        }
    }
}

// MARK: - Public (Voice Chrome)

public extension VoiceChromePresenter {
    /// Present `NuguVoiceChrome`
    ///
    /// - Parameter chipsData:
    /// - Throws: An error of type `VoiceChromePresenterError`
    func presentVoiceChrome(chipsData: [NuguChipsButton.NuguChipsButtonType]? = nil) throws {
        guard NetworkReachabilityManager.shared.isReachable else { throw VoiceChromePresenterError.networkUnreachable }
        log.debug("")
        
        if let chipsData = chipsData {
            nuguVoiceChrome.setChipsData(chipsData) { [weak self] chips in
                self?.delegate?.voiceChromeChipsDidClick(chips: chips)
            }
        }
        voiceChromeDismissWorkItem?.cancel()
        nuguVoiceChrome.removeFromSuperview()
        nuguVoiceChrome.changeState(state: .listeningPassive)
        if nuguClient?.dialogStateAggregator.sessionActivated == true {
            nuguVoiceChrome.setRecognizedText(text: nil)
        }
        
        try showVoiceChrome()
    }
    
    /// Dismiss `NuguVoiceChrome`
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
        guard isHidden == true else { throw VoiceChromePresenterError.alreadyShown      }
        
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
        var chipsData = [NuguChipsButton.NuguChipsButtonType]()
        let actionButtonList = actionList.map { NuguChipsButton.NuguChipsButtonType.action(text: $0.text, token: $0.token) }
        chipsData.append(contentsOf: actionButtonList)
        let normalButtonList = normalList.map { NuguChipsButton.NuguChipsButtonType.normal(text: $0.text, token: $0.token) }
        chipsData.append(contentsOf: normalButtonList)
        nuguVoiceChrome.setChipsData(chipsData) { [weak self] chips in
            self?.delegate?.voiceChromeChipsDidClick(chips: chips)
        }
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

// MARK: - Observers

/// :nodoc:
private extension VoiceChromePresenter {
    func addInteractionControlObserver(_ object: InteractionControlManageable) {
        interactionControlObserver = object.observe(NuguAgentNotification.InteractionControl.MultiTurn.self, queue: .main) { [weak self] (notification) in
            guard let self = self else { return }
            
            self.isMultiturn = notification.multiTurn
            if notification.multiTurn {
                self.disableIdleTimer()
            } else {
                self.enableIdleTimer()
            }
        }
    }
    
    func addAsrAgentObserver(_ object: ASRAgentProtocol) {
        asrStateObserver = object.observe(NuguAgentNotification.ASR.State.self, queue: .main) { [weak self] (notification) in
            guard let self = self else { return }
            
            self.asrState = notification.state
            switch notification.state {
            case .idle:
                self.enableIdleTimer()
            default:
                self.disableIdleTimer()
            }
        }
        
        asrResultObserver = object.observe(NuguAgentNotification.ASR.Result.self, queue: .main) { [weak self] (notification) in
            guard let self = self else { return }
            
            switch notification.result {
            case .complete(let text, _):
                self.nuguVoiceChrome.setRecognizedText(text: text)
                self.asrBeepPlayer?.beep(type: .success)
            case .partial(let text, _):
                self.nuguVoiceChrome.setRecognizedText(text: text)
            case .error(let error, _):
                switch error {
                case ASRError.listenFailed:
                    self.nuguVoiceChrome.changeState(state: .speakingError)
                    self.asrBeepPlayer?.beep(type: .fail)
                case ASRError.recognizeFailed:
                    break
                default:
                    self.asrBeepPlayer?.beep(type: .fail)
                }
            default: break
            }
        }
    }
    
    func addDialogStateObserver(_ object: DialogStateAggregator) {
        dialogStateObserver = object.observe(NuguClientNotification.DialogState.State.self, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            log.debug("\(notification.state) \(notification.multiTurn), \(notification.chips.debugDescription)")

            switch notification.state {
            case .idle:
                self.voiceChromeDismissWorkItem = DispatchWorkItem(block: { [weak self] in
                    self?.dismissVoiceChrome()
                })
                guard let voiceChromeDismissWorkItem = self.voiceChromeDismissWorkItem else { break }
                DispatchQueue.main.async(execute: voiceChromeDismissWorkItem)
            case .speaking:
                self.voiceChromeDismissWorkItem?.cancel()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard notification.multiTurn == true else {
                        self.dismissVoiceChrome()
                        return
                    }
                    // If voice chrome is not showing or dismissing in speaking state, voice chrome should be presented
                    try? self.showVoiceChrome()
                    self.nuguVoiceChrome.changeState(state: .speaking)
                    if let chips = notification.chips {
                        let actionList = chips.filter { $0.type == .action }.map { ($0.text, $0.token) }
                        let normalList = chips.filter { $0.type == .general }.map { ($0.text, $0.token) }
                        self.setChipsButton(actionList: actionList, normalList: normalList)
                    }
                }
            case .listening:
                self.voiceChromeDismissWorkItem?.cancel()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // If voice chrome is not showing or dismissing in listening state, voice chrome should be presented
                    try? self.showVoiceChrome()
                    if notification.multiTurn || notification.sessionActivated {
                        if self.nuguVoiceChrome.currentState != .listeningPassive {
                            self.nuguVoiceChrome.changeState(state: .listeningPassive)
                        }
                        self.nuguVoiceChrome.setRecognizedText(text: nil)
                    }
                    if let chips = notification.chips {
                        let actionList = chips.filter { $0.type == .action }.map { ($0.text, $0.token) }
                        let normalList = chips.filter { $0.type == .general }.map { ($0.text, $0.token) }
                        self.setChipsButton(actionList: actionList, normalList: normalList)
                    }
                    self.asrBeepPlayer?.beep(type: .start)
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
}

// MARK: - UIGestureRecognizerDelegate

extension VoiceChromePresenter: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchLocation = touch.location(in: gestureRecognizer.view)
        return !nuguVoiceChrome.frame.contains(touchLocation)
    }
}

@objc private extension VoiceChromePresenter {
    func didTapForStopRecognition() {
        guard let nuguClient = nuguClient else { return }
        
        guard [.listening, .recognizing].contains(nuguClient.asrAgent.asrState) else { return }
        nuguClient.asrAgent.stopRecognition()
    }
}
