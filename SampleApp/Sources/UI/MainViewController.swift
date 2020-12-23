//
//  MainViewController.swift
//  SampleApp
//
//  Created by jin kim on 17/06/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
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
import MediaPlayer

import NuguCore
import NuguAgents
import NuguClientKit
import NuguUIKit

final class MainViewController: UIViewController {
    var resignActiveObserver: Any?
    var becomeActiveObserver: Any?
    
    // MARK: Properties
    
    @IBOutlet private weak var nuguButton: NuguButton!
    @IBOutlet private weak var settingButton: UIButton!
    @IBOutlet private weak var watermarkLabel: UILabel!
    @IBOutlet private weak var textInputTextField: UITextField!
        
    private weak var displayView: NuguDisplayWebView?
    private weak var displayAudioPlayerView: AudioDisplayView?
    
    private lazy var nuguVoiceChrome: NuguVoiceChrome = {
        NuguVoiceChrome(frame: CGRect())
    }()
    private lazy var voiceChromePresenter: VoiceChromePresenter = {
        VoiceChromePresenter(
            viewController: self,
            nuguVoiceChrome: nuguVoiceChrome,
            nuguClient: NuguCentralManager.shared.client
        )
    }()
    
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientBackground()
        addWatermarkLabel()
        initializeNugu()
        registerObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshNugu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showGuideWebIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NuguCentralManager.shared.stopMicInputProvider()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let segueId = segue.identifier else {
            log.debug("segue identifier is nil")
            return
        }
        
        switch segueId {
        case "mainToGuideWeb":
            guard let webViewController = segue.destination as? WebViewController else { return }
            webViewController.initialURL = sender as? URL
            
            UserDefaults.Standard.hasSeenGuideWeb = true
        default:
            return
        }
    }
    
    // MARK: Deinitialize
    
    deinit {
        removeObservers()
    }
}

// MARK: - private (Observer)

private extension MainViewController {
    func registerObservers() {
        // To avoid duplicated observing
        removeObservers()
        
        /**
         Catch resigning active notification to stop recognizing & wake up detector
         It is possible to keep on listening even on background, but need careful attention for battery issues, audio interruptions and so on
         */
        resignActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main, using: { (notification) in
            // if tts is playing for multiturn, tts and associated jobs should be stopped when resign active
            if NuguCentralManager.shared.client.dialogStateAggregator.isMultiturn == true {
                NuguCentralManager.shared.client.ttsAgent.stopTTS()
            }
            NuguCentralManager.shared.client.asrAgent.stopRecognition()
            NuguCentralManager.shared.stopMicInputProvider()
        })
        
        /**
         Catch becoming active notification to refresh mic status & Nugu button
         Recover all status for any issues caused from becoming background
         */
        becomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: { [weak self] (notification) in
            guard let self = self else { return }
            guard self.navigationController?.visibleViewController == self else { return }

            self.refreshNugu()
        })
    }
    
    func removeObservers() {
        if let resignActiveObserver = resignActiveObserver {
            NotificationCenter.default.removeObserver(resignActiveObserver)
            self.resignActiveObserver = nil
        }

        if let becomeActiveObserver = becomeActiveObserver {
            NotificationCenter.default.removeObserver(becomeActiveObserver)
            self.becomeActiveObserver = nil
        }
    }
}
    
@objc private extension MainViewController {
    func didTapForStopRecognition() {
        guard [.listening, .recognizing].contains(NuguCentralManager.shared.client.asrAgent.asrState) else { return }
        NuguCentralManager.shared.client.asrAgent.stopRecognition()
    }
}

// MARK: - Private (IBAction)

private extension MainViewController {
    @IBAction func showSettingsButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.stopMicInputProvider()

        performSegue(withIdentifier: "showSettings", sender: nil)
    }
    
    @IBAction func startRecognizeButtonDidClick(_ button: UIButton) {
        presentVoiceChrome(initiator: .user)
    }
    
    @IBAction func sendTextInput(_ button: UIButton) {
        guard let textInput = textInputTextField.text else { return }
        textInputTextField.resignFirstResponder()
        NuguCentralManager.shared.requestTextInput(text: textInput, requestType: .normal)
    }
}

// MARK: - Private (Nugu)

private extension MainViewController {
    /// Initialize to start using Nugu
    /// AudioSession is required for using Nugu
    /// Add delegates for all the components that provided by default client or custom provided ones
    func initializeNugu() {
        // Set AudioSession
        NuguAudioSessionManager.shared.updateAudioSession()
        
        // Add delegates
        NuguCentralManager.shared.client.keywordDetector.delegate = self
        NuguCentralManager.shared.client.dialogStateAggregator.add(delegate: self)
        NuguCentralManager.shared.client.asrAgent.add(delegate: self)
        NuguCentralManager.shared.client.displayAgent.delegate = self
        NuguCentralManager.shared.client.audioPlayerAgent.displayDelegate = self
        NuguCentralManager.shared.client.audioPlayerAgent.add(delegate: self)
        
        // UI
        voiceChromePresenter.delegate = self
        nuguVoiceChrome.onChipsSelect = { [weak self] selectedChips in
            self?.chipsDidSelect(selectedChips: selectedChips)
        }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapForStopRecognition))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    /// Show nugu usage guide webpage after successful login process
    func showGuideWebIfNeeded() {
        ConfigurationStore.shared.usageGuideUrl(deviceUniqueId: NuguCentralManager.shared.oauthClient.deviceUniqueId) { [weak self] (result) in
            switch result {
            case .success(let urlString):
                if let url = URL(string: urlString) {
                    self?.performSegue(withIdentifier: "mainToGuideWeb", sender: url)
                }
            case .failure(let error):
                log.error(error)
            }
        }
    }
    
    /// Refresh Nugu status
    /// Connect or disconnect Nugu service by circumstance
    /// Hide Nugu button when Nugu service is intended not to use or network issue has occured
    /// Disable Nugu button when wake up feature is intended not to use
    func refreshNugu() {
        guard UserDefaults.Standard.useNuguService else {
            // Exception handling when already disconnected, scheduled update in future
            nuguButton.isEnabled = false
            nuguButton.isHidden = true
            
            // Disable Nugu SDK
            NuguCentralManager.shared.disable()
            return
        }
        
        // Exception handling when already connected, scheduled update in future
        nuguButton.isEnabled = true
        nuguButton.isHidden = false
        
        // Enable Nugu SDK
        NuguCentralManager.shared.enable()
    }
}

// MARK: - Private (View)

private extension MainViewController {
    func setGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [UIColor(rgbHexValue: 0x798492).cgColor, UIColor(rgbHexValue: 0xbac7d7).cgColor]
        gradientLayer.locations =  [0, 1.0]
        gradientLayer.frame = view.frame
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    /// Not neccesary (just need for watermark)
    func addWatermarkLabel() {
        guard let currentloginMethod = SampleApp.LoginMethod(rawValue: UserDefaults.Standard.currentloginMethod) else {
            watermarkLabel.text = "오류"
            return
        }
        
        watermarkLabel.text = "\(currentloginMethod.name) mode"
    }
}

// MARK: - Private (Voice Chrome)

private extension MainViewController {
    func presentVoiceChrome(initiator: ASRInitiator) {
        nuguVoiceChrome.setChipsData(chipsData: [
            NuguChipsButton.NuguChipsButtonType.action(text: "오늘 날씨 알려줘", token: nil),
            NuguChipsButton.NuguChipsButtonType.action(text: "습도 알려줘", token: nil),
            NuguChipsButton.NuguChipsButtonType.normal(text: "라디오 목록 알려줘", token: nil),
            NuguChipsButton.NuguChipsButtonType.normal(text: "주말 날씨 알려줘", token: nil),
            NuguChipsButton.NuguChipsButtonType.normal(text: "오존 농도 알려줘", token: nil),
            NuguChipsButton.NuguChipsButtonType.normal(text: "멜론 틀어줘", token: nil),
            NuguChipsButton.NuguChipsButtonType.normal(text: "NUGU 토픽 알려줘", token: nil)
        ])
        
        do {
            try voiceChromePresenter.presentVoiceChrome()
            NuguCentralManager.shared.startRecognition(initiator: initiator)
            NuguCentralManager.shared.startMicInputProvider(requestingFocus: true) { success in
                guard success else {
                    log.error("Start MicInputProvider failed")
                    NuguCentralManager.shared.stopRecognition()
                    return
                }
            }
        } catch {
            switch error {
            case VoiceChromePresenterError.networkUnreachable:
                NuguCentralManager.shared.localTTSAgent.playLocalTTS(type: .deviceGatewayNetworkError)
            default:
                log.error(error)
            }
        }
    }
}

// MARK: - Private (Chips Selection)

private extension MainViewController {
    func chipsDidSelect(selectedChips: NuguChipsButton.NuguChipsButtonType?) {
        guard let selectedChips = selectedChips,
            let window = UIApplication.shared.keyWindow else { return }
        
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = .black
        indicator.startAnimating()
        indicator.center = window.center
        indicator.startAnimating()
        window.addSubview(indicator)
        
        NuguCentralManager.shared.requestTextInput(text: selectedChips.text, token: selectedChips.token, requestType: .dialog) {
            DispatchQueue.main.async {
                indicator.removeFromSuperview()
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MainViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchLocation = touch.location(in: gestureRecognizer.view)
        return !nuguVoiceChrome.frame.contains(touchLocation)
    }
}

// MARK: - Private (DisplayView)

private extension MainViewController {
    func replaceDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        guard let displayView = self.displayView else {
            completion(nil)
            return
        }
        displayView.load(
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: ["buttonColor": "white"]
        )
        displayView.onItemSelect = { (token, postback) in
            NuguCentralManager.shared.client.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        completion(displayView)
    }
    
    func addDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        if let displayView = self.displayView,
           view.subviews.contains(displayView) {
            replaceDisplayView(displayTemplate: displayTemplate, completion: completion)
            return
        }
        let displayView = NuguDisplayWebView(frame: view.frame)
        displayView.load(
            displayPayload: displayTemplate.payload,
            displayType: displayTemplate.type,
            clientInfo: ["buttonColor": "white"]
        )
        displayView.onClose = { [weak self] in
            guard let self = self else { return }
            NuguCentralManager.shared.client.ttsAgent.stopTTS()
            self.dismissDisplayView()
        }
        // TODO: - EventType 꼭 확인할것 (웹에선 무시하는건지?)
        displayView.onItemSelect = { (token, postback) in
            NuguCentralManager.shared.client.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
        }
        displayView.onUserInteraction = {
            NuguCentralManager.shared.client.displayAgent.notifyUserInteraction()
        }
        displayView.onTapForStopRecognition = { [weak self] in
            self?.didTapForStopRecognition()
        }
        displayView.onChipsSelect = { (selectedChips) in
            NuguCentralManager.shared.requestTextInput(text: selectedChips, requestType: .dialog)
        }
        displayView.onNuguButtonClick = { [weak self] in
            self?.presentVoiceChrome(initiator: .user)
        }
        
        displayView.alpha = 0
        view.insertSubview(displayView, belowSubview: nuguVoiceChrome)
        
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "btn_close"), for: .normal)
        closeButton.frame = CGRect(x: displayView.frame.size.width - 48, y: SafeAreaUtil.topSafeAreaHeight + 16, width: 28.0, height: 28.0)
        closeButton.addTarget(self, action: #selector(self.onDisplayViewCloseButtonDidClick), for: .touchUpInside)
        displayView.addSubview(closeButton)
        
        UIView.animate(withDuration: 0.3, animations: {
            displayView.alpha = 1.0
        }, completion: { [weak self] (_) in
            completion(displayView)
            self?.displayView = displayView
        })
    }
    
    @objc func onDisplayViewCloseButtonDidClick() {
        NuguCentralManager.shared.client.ttsAgent.stopTTS()
        dismissDisplayView()
    }
    
    func updateDisplayView(displayTemplate: DisplayTemplate) {
        displayView?.update(updatePayload: displayTemplate.payload)
    }
    
    func dismissDisplayView() {
        guard let view = displayView else { return }
        UIView.animate(
            withDuration: 0.3,
            animations: {
                view.alpha = 0
            },
            completion: { _ in
                view.removeFromSuperview()
            }
        )
    }
}

// MARK: - Private (AudioDisplayView)

private extension MainViewController {
    func replaceDisplayView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        guard let displayAudioPlayerView = self.displayAudioPlayerView else {
            completion(nil)
            return
        }
        displayAudioPlayerView.displayPayload = audioPlayerDisplayTemplate.payload
        completion(displayAudioPlayerView)
    }
    
    func addDisplayAudioPlayerView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        if let displayAudioPlayerView = self.displayAudioPlayerView,
           view.subviews.contains(displayAudioPlayerView) == true {
            replaceDisplayView(audioPlayerDisplayTemplate: audioPlayerDisplayTemplate, completion: completion)
            return
        }
        displayAudioPlayerView?.removeFromSuperview()
        guard let audioPlayerView = AudioDisplayView.makeDisplayAudioPlayerView(audioPlayerDisplayTemplate: audioPlayerDisplayTemplate, frame: view.frame) else {
            completion(nil)
            return
        }
        audioPlayerView.delegate = self
        audioPlayerView.displayPayload = audioPlayerDisplayTemplate.payload
        
        audioPlayerView.alpha = 0
        view.insertSubview(audioPlayerView, belowSubview: nuguVoiceChrome)
        UIView.animate(withDuration: 0.3) {
            audioPlayerView.alpha = 1.0
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            audioPlayerView.alpha = 1.0
        }, completion: { [weak self] (_) in
            completion(audioPlayerView)
            self?.displayAudioPlayerView = audioPlayerView
        })
    }
    
    func dismissDisplayAudioPlayerView() {
        guard let view = displayAudioPlayerView else { return }
        UIView.animate(
            withDuration: 0.3,
            animations: {
                view.alpha = 0
            },
            completion: { _ in
                view.removeFromSuperview()
            }
        )
    }
}

// MARK: - KeywordDetectorDelegate

extension MainViewController: KeywordDetectorDelegate {
    func keywordDetectorDidDetect(keyword: String?, data: Data, start: Int, end: Int, detection: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.presentVoiceChrome(initiator: .wakeUpKeyword(
                keyword: keyword,
                data: data,
                start: start,
                end: end,
                detection: detection
                )
            )
        }
    }
    
    func keywordDetectorDidStop() {}
    
    func keywordDetectorStateDidChange(_ state: KeywordDetectorState) {
        switch state {
        case .active:
            DispatchQueue.main.async { [weak self] in
                self?.nuguButton.startFlipAnimation()
            }
        case .inactive:
            DispatchQueue.main.async { [weak self] in
                self?.nuguButton.stopFlipAnimation()
            }
        }
    }
    
    func keywordDetectorDidError(_ error: Error) {}
}

// MARK: - VoiceChromePresenterDelegate

extension MainViewController: VoiceChromePresenterDelegate {
    func voiceChromeWillShow() {
        nuguButton.isActivated = false
    }
    
    func voiceChromeWillHide() {
        nuguButton.isActivated = true
    }
    
    func voiceChromeShouldDisableIdleTimer() -> Bool {
        true
    }
    
    func voiceChromeShouldEnableIdleTimer() -> Bool {
        true
    }
}

// MARK: - DialogStateDelegate

extension MainViewController: DialogStateDelegate {
    func dialogStateDidChange(_ state: DialogState, isMultiturn: Bool, chips: [ChipsAgentItem.Chip]?, sessionActivated: Bool) {
        log.debug("\(state) \(isMultiturn), \(chips.debugDescription)")
        switch state {
        case .listening:
            DispatchQueue.main.async {
                NuguCentralManager.shared.asrBeepPlayer.beep(type: .start)
            }
        case .thinking:
            DispatchQueue.main.async { [weak self] in
                self?.nuguButton.pauseDeactivateAnimation()
            }
        default:
            break
        }
    }
}

// MARK: - AutomaticSpeechRecognitionDelegate

extension MainViewController: ASRAgentDelegate {
    func asrAgentDidChange(state: ASRState) {
        switch state {
        case .idle:
            if UserDefaults.Standard.useWakeUpDetector == true {
                NuguCentralManager.shared.startWakeUpDetector()
            } else {
                NuguCentralManager.shared.stopMicInputProvider()
            }
        case .listening:
            NuguCentralManager.shared.stopWakeUpDetector()
        case .expectingSpeech:
            NuguCentralManager.shared.startMicInputProvider(requestingFocus: true) { (success) in
                guard success == true else {
                    log.debug("startMicInputProvider failed!")
                    NuguCentralManager.shared.stopRecognition()
                    return
                }
            }
        default:
            break
        }
    }
    
    func asrAgentDidReceive(result: ASRResult, dialogRequestId: String) {
        switch result {
        case .complete:
            DispatchQueue.main.async {
                NuguCentralManager.shared.asrBeepPlayer.beep(type: .success)
            }
        case .error(let error, _):
            DispatchQueue.main.async {
                switch error {
                case ASRError.listenFailed:
                    NuguCentralManager.shared.asrBeepPlayer.beep(type: .fail)
                case ASRError.recognizeFailed:
                    NuguCentralManager.shared.localTTSAgent.playLocalTTS(type: .deviceGatewayRequestUnacceptable)
                default:
                    NuguCentralManager.shared.asrBeepPlayer.beep(type: .fail)
                }
            }
        default: break
        }
    }
}

// MARK: - DisplayAgentDelegate

extension MainViewController: DisplayAgentDelegate {
    func displayAgentRequestContext(templateId: String, completion: @escaping (DisplayContext?) -> Void) {
        displayView?.requestContext(completion: { (displayContext) in
            completion(displayContext)
        })
    }
    
    func displayAgentShouldMoveFocus(templateId: String, direction: DisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
    
    func displayAgentShouldScroll(templateId: String, direction: DisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.displayView?.scroll(direction: direction, completion: completion)
        }
    }
    
    func displayAgentShouldRender(template: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        log.debug("templateId: \(template.templateId)")
        DispatchQueue.main.async {  [weak self] in
            self?.addDisplayView(displayTemplate: template, completion: completion)
        }
    }
    
    func displayAgentShouldUpdate(templateId: String, template: DisplayTemplate) {
        log.debug("templateId: \(templateId)")
        DispatchQueue.main.async { [weak self] in
            self?.updateDisplayView(displayTemplate: template)
        }
    }
    
    func displayAgentDidClear(templateId: String) {
        log.debug("templateId: \(templateId)")
        DispatchQueue.main.async { [weak self] in
            self?.dismissDisplayView()
        }
    }
}

// MARK: - DisplayPlayerAgentDelegate

extension MainViewController: AudioPlayerDisplayDelegate {
    func audioPlayerDisplayShouldShowLyrics(header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.displayAudioPlayerView?.shouldShowLyrics() ?? false)
        }
    }
    
    func audioPlayerDisplayShouldHideLyrics(header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.displayAudioPlayerView?.shouldHideLyrics() ?? false)
        }
    }
    
    func audioPlayerIsLyricsVisible(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.displayAudioPlayerView?.isLyricsVisible ?? false)
        }
    }
    
    func audioPlayerDisplayShouldControlLyricsPage(direction: AudioPlayerDisplayControlPayload.Direction, header: Downstream.Header, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            completion(false)
        }
    }
    
    func audioPlayerDisplayShouldRender(template: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        log.debug("")
        DispatchQueue.main.async { [weak self] in
            NuguCentralManager.shared.displayPlayerController.update(template)
            self?.addDisplayAudioPlayerView(audioPlayerDisplayTemplate: template, completion: completion)
        }
    }
    
    func audioPlayerDisplayDidClear(template: AudioPlayerDisplayTemplate) {
        log.debug("")
        DispatchQueue.main.async { [weak self] in
            NuguCentralManager.shared.displayPlayerController.remove()
            self?.dismissDisplayAudioPlayerView()
        }
    }
    
    func audioPlayerDisplayShouldUpdateMetadata(payload: Data, header: Downstream.Header) {
        DispatchQueue.main.async { [weak self] in
            self?.displayAudioPlayerView?.updateSettings(payload: payload)
        }
    }
}

// MARK: - AudioPlayerAgentDelegate

extension MainViewController: AudioPlayerAgentDelegate {
    func audioPlayerAgentDidChange(state: AudioPlayerState, header: Downstream.Header) {
        log.debug("audioPlayerAgentDidChange : \(state)")
        NuguCentralManager.shared.displayPlayerController.update(state)
        NuguAudioSessionManager.shared.pausedByInterruption = false
        if state == .playing {
            NuguAudioSessionManager.shared.updateAudioSessionToPlaybackIfNeeded()
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                let displayAudioPlayerView = self.displayAudioPlayerView else { return }
            displayAudioPlayerView.audioPlayerState = state
        }
    }
    
    func audioPlayerAgentDidChange(duration: Int) {
        NuguCentralManager.shared.displayPlayerController.update(duration)
    }
}

// MARK: - AudioDisplayViewDelegate

extension MainViewController: AudioDisplayViewDelegate {
    func onCloseButtonClick() {
        dismissDisplayAudioPlayerView()
        NuguCentralManager.shared.displayPlayerController.remove()
    }
    
    func onUserInteraction() {
        NuguCentralManager.shared.client.audioPlayerAgent.notifyUserInteraction()
    }
    
    func onNuguButtonClick() {
        presentVoiceChrome(initiator: .user)
    }
    
    func onChipsSelect(selectedChips: NuguChipsButton.NuguChipsButtonType?) {
        chipsDidSelect(selectedChips: selectedChips)
    }
    
    func onPreviousButtonClick() {
        NuguCentralManager.shared.client.audioPlayerAgent.prev()
    }
    
    func onPlayButtonClick() {
        NuguCentralManager.shared.client.audioPlayerAgent.play()
    }
    
    func onPauseButtonClick() {
        NuguCentralManager.shared.client.audioPlayerAgent.pause()
    }
    
    func onNextButtonClick() {
        NuguCentralManager.shared.client.audioPlayerAgent.next()
    }
    
    func onFavoriteButtonClick(current: Bool) {
        NuguCentralManager.shared.client.audioPlayerAgent.requestFavoriteCommand(current: current)
    }
    
    func onRepeatButtonDidClick(currentMode: AudioPlayerDisplayRepeat) {
        NuguCentralManager.shared.client.audioPlayerAgent.requestRepeatCommand(currentMode: currentMode)
    }
    
    func onShuffleButtonDidClick(current: Bool) {
        NuguCentralManager.shared.client.audioPlayerAgent.requestShuffleCommand(current: current)
    }
    
    func requestAudioPlayerIsPlaying() -> Bool? {
        return NuguCentralManager.shared.client.audioPlayerAgent.isPlaying
    }
    
    func requestOffset() -> Int? {
        return NuguCentralManager.shared.client.audioPlayerAgent.offset
    }
    
    func requestDuration() -> Int? {
        return NuguCentralManager.shared.client.audioPlayerAgent.duration
    }
}
