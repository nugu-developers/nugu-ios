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
    private weak var themeController: NuguThemeController?
    private weak var viewController: UIViewController?
    private weak var superView: UIView?
    private var targetView: UIView? {
        superView ?? viewController?.view
    }
    private var asrBeepPlayer: ASRBeepPlayer?
    
    private var speechState: SpeechRecognizerAggregatorState = .idle
    private var isMultiturn: Bool = false
    private var voiceChromeDismissWorkItem: DispatchWorkItem?
    
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapForStopRecognition))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.cancelsTouchesInView = false
        
        return tapGestureRecognizer
    }()
    
    private var voiceChromeHeight: CGFloat {
        NuguVoiceChrome.recommendedHeight + SafeAreaUtil.bottomSafeAreaHeight
    }
    
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
    private var dialogStateObserver: Any?
    private var speechStateObserver: Any?
    private var themeObserver: Any?
    
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
        asrBeepPlayerResourcesURL: ASRBeepPlayerResourcesURL = ASRBeepPlayerResourcesURL(),
        themeController: NuguThemeController? = nil
    ) {
        self.init(nuguVoiceChrome: nuguVoiceChrome, nuguClient: nuguClient, asrBeepPlayerResourcesURL: asrBeepPlayerResourcesURL, themeController: themeController)
        
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
        asrBeepPlayerResourcesURL: ASRBeepPlayerResourcesURL = ASRBeepPlayerResourcesURL(),
        themeController: NuguThemeController? = nil
    ) {
        self.init(nuguVoiceChrome: nuguVoiceChrome, nuguClient: nuguClient, asrBeepPlayerResourcesURL: asrBeepPlayerResourcesURL, themeController: themeController)
        
        self.viewController = viewController
    }
    
    private init(
        nuguVoiceChrome: NuguVoiceChrome?,
        nuguClient: NuguClient,
        asrBeepPlayerResourcesURL: ASRBeepPlayerResourcesURL,
        themeController: NuguThemeController? = nil
    ) {
        self.nuguVoiceChrome = nuguVoiceChrome ?? NuguVoiceChrome(frame: CGRect())
        self.nuguClient = nuguClient
        self.themeController = themeController
        self.asrBeepPlayer = ASRBeepPlayer(focusManager: nuguClient.focusManager, resourcesUrl: asrBeepPlayerResourcesURL)
        
        super.init()
        
        // Observers
        addInteractionControlObserver(nuguClient.interactionControlManager)
        addDialogStateObserver(nuguClient.dialogStateAggregator)
        addSpeechStateObserver()
        if let themeController = themeController {
            addThemeControllerObserver(themeController)
            self.nuguVoiceChrome.theme = themeController.theme == .dark ? .dark : .light
        }
    }
    
    deinit {
        if let interactionControlObserver = interactionControlObserver {
            notificationCenter.removeObserver(interactionControlObserver)
        }
        
        if let dialogStateObserver = dialogStateObserver {
            notificationCenter.removeObserver(dialogStateObserver)
        }
        
        if let themeObserver = themeObserver {
            notificationCenter.removeObserver(themeObserver)
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
            self.nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: self.voiceChromeHeight)
        }, completion: { [weak self] _ in
            guard let self = self,
                  self.isHidden == true else { return }
            self.nuguVoiceChrome.removeFromSuperview()
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
        
        if let themeController = themeController {
            switch themeController.theme {
            case .dark:
                nuguVoiceChrome.theme = .dark
            case .light:
                nuguVoiceChrome.theme = .light
            }
        }
        let showAnimation = {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: 0)
            }
        }
        if view.subviews.contains(nuguVoiceChrome) == false {
            view.addSubview(nuguVoiceChrome)
            nuguVoiceChrome.translatesAutoresizingMaskIntoConstraints = false
            nuguVoiceChrome.heightAnchor.constraint(equalToConstant: voiceChromeHeight).isActive = true
            nuguVoiceChrome.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            nuguVoiceChrome.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            nuguVoiceChrome.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: voiceChromeHeight)
        }
        showAnimation()
    }
    
    func setChipsButton(nudgeList: [(text: String, token: String?)] = [], actionList: [(text: String, token: String?)], normalList: [(text: String, token: String?)]) {
        let nudgeButtonList = nudgeList.map { NuguChipsButton.NuguChipsButtonType.nudge(text: $0.text, token: $0.token) }
        let actionButtonList = actionList.map { NuguChipsButton.NuguChipsButtonType.action(text: $0.text, token: $0.token) }
        let normalButtonList = normalList.map { NuguChipsButton.NuguChipsButtonType.normal(text: $0.text, token: $0.token) }
        nuguVoiceChrome.setChipsData(nudgeButtonList + actionButtonList + normalButtonList) { [weak self] chips in
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
        guard isMultiturn == false else { return }
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
    
    func addDialogStateObserver(_ object: DialogStateAggregator) {
        dialogStateObserver = object.observe(NuguClientNotification.DialogState.State.self, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            log.debug("\(notification.state) \(notification.multiTurn), \(notification.item.debugDescription)")

            switch notification.state {
            case .idle:
                self.voiceChromeDismissWorkItem = DispatchWorkItem(block: { [weak self] in
                    if notification.item == nil {
                        self?.nuguVoiceChrome.setChipsData([])
                    }
                    self?.dismissVoiceChrome()
                })
                guard let voiceChromeDismissWorkItem = self.voiceChromeDismissWorkItem else { break }
                DispatchQueue.main.async(execute: voiceChromeDismissWorkItem)
            case .speaking:
                self.voiceChromeDismissWorkItem?.cancel()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard notification.sessionActivated == true,
                          notification.multiTurn == true || notification.item?.target == .speaking else {
                        self.dismissVoiceChrome()
                        return
                    }
                    // If voice chrome is not showing or dismissing in speaking state, voice chrome should be presented
                    try? self.showVoiceChrome()
                    self.nuguVoiceChrome.changeState(state: .speaking)
                    if let chips = notification.item?.chips {
                        let nudgeList = chips.filter { $0.type == .nudge }.map { ($0.text, $0.token) }
                        let actionList = chips.filter { $0.type == .action }.map { ($0.text, $0.token) }
                        let normalList = chips.filter { $0.type == .general }.map { ($0.text, $0.token) }
                        self.setChipsButton(nudgeList: nudgeList, actionList: actionList, normalList: normalList)
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
                    if let chips = notification.item?.chips {
                        let nudgeList = chips.filter { $0.type == .nudge }.map { ($0.text, $0.token) }
                        let actionList = chips.filter { $0.type == .action }.map { ($0.text, $0.token) }
                        let normalList = chips.filter { $0.type == .general }.map { ($0.text, $0.token) }
                        self.setChipsButton(nudgeList: nudgeList, actionList: actionList, normalList: normalList)
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
            
            DispatchQueue.main.async {
                switch notification.state {
                case .idle:
                    self.enableIdleTimer()
                default:
                    self.disableIdleTimer()
                }
            }
        }
    }
    
    func addSpeechStateObserver() {
        speechStateObserver = notificationCenter.addObserver(
            forName: NuguClient.speechStateChangedNotification,
            object: nuguClient,
            queue: .main,
            using: { [weak self] (notification) in
                guard let self = self,
                      let state = notification.userInfo?["state"] as? SpeechRecognizerAggregatorState else { return }
                self.speechState = state
                switch state {
                case .result(let result):
                    switch result.type {
                    case .complete:
                        self.nuguVoiceChrome.setRecognizedText(text: result.value)
                        self.asrBeepPlayer?.beep(type: .success)
                    case .partial:
                        self.nuguVoiceChrome.setRecognizedText(text: result.value)
                    }
                case .error(let error):
                    if let asrError = error as? ASRError, [ASRError.listenFailed, ASRError.recognizeFailed].contains(asrError) == true {
                        self.asrBeepPlayer?.beep(type: .fail)
                        self.nuguVoiceChrome.changeState(state: .speakingError)
                    } else if error as? SpeechRecognizerAggregatorError != nil {
                        self.dismissVoiceChrome()
                    } else if case ASRError.listeningTimeout(let listenTimeoutFailBeep) = error {
                        if listenTimeoutFailBeep == true {
                            self.asrBeepPlayer?.beep(type: .fail)
                        }
                    }
                default: break
                }
        })
    }
    
    func addThemeControllerObserver(_ object: NuguThemeController) {
        themeObserver = object.observe(NuguClientNotification.NuguThemeState.Theme.self, queue: .main, using: { [weak self] notification in
            guard let self = self else { return }
            switch notification.theme {
            case .dark:
                self.nuguVoiceChrome.theme = .dark
            case .light:
                self.nuguVoiceChrome.theme = .light
            }
        })
    }
}

// MARK: - UIGestureRecognizerDelegate

extension VoiceChromePresenter: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchLocation = touch.location(in: gestureRecognizer.view)
        return !nuguVoiceChrome.frame.contains(touchLocation)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

@objc private extension VoiceChromePresenter {
    func didTapForStopRecognition() {
        guard let nuguClient = nuguClient else { return }
        
        guard [.listening(), .recognizing].contains(nuguClient.asrAgent.asrState) else { return }
        nuguClient.asrAgent.stopRecognition()
    }
}
