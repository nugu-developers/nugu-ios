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
    
    // MARK: Properties
    
    @IBOutlet private weak var nuguButton: NuguButton!
    @IBOutlet private weak var settingButton: UIButton!
    @IBOutlet private weak var watermarkLabel: UILabel!
    
    private var voiceChromeDismissWorkItem: DispatchWorkItem?
    
    private var displayView: DisplayView?
    private var displayAudioPlayerView: DisplayAudioPlayerView?
    
    private var nuguVoiceChrome = NuguVoiceChrome()
    
    private var hasShownGuideWeb = false
    
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientBackground()
        addWatermarkLabel()
        initializeNugu()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive(_:)),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
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
        
        NuguCentralManager.shared.stopWakeUpDetector()
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
            
            hasShownGuideWeb = true
        default:
            return
        }
    }
    
    // MARK: Deinitialize
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Private (Selector)

@objc private extension MainViewController {
    
    /// Catch resigning active notification to stop recognizing & wake up detector
    /// It is possible to keep on listening even on background, but need careful attention for battery issues, audio interruptions and so on
    /// - Parameter notification: UIApplication.willResignActiveNotification
    func willResignActive(_ notification: Notification) {
        dismissVoiceChrome()
        NuguCentralManager.shared.stopWakeUpDetector()
    }
    
    /// Catch becoming active notification to refresh mic status & Nugu button
    /// Recover all status for any issues caused from becoming background
    /// - Parameter notification: UIApplication.didBecomeActiveNotification
    func didBecomeActive(_ notification: Notification) {
        guard navigationController?.visibleViewController == self else { return }
        refreshNugu()
    }
}

// MARK: - Private (IBAction)

private extension MainViewController {
    @IBAction func showSettingsButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.stopWakeUpDetector()

        performSegue(withIdentifier: "showSettings", sender: nil)
    }
    
    @IBAction func startRecognizeButtonDidClick(_ button: UIButton) {
        presentVoiceChrome(initiator: .user)
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
        NuguCentralManager.shared.client.textAgent.delegate = self
        NuguCentralManager.shared.client.displayAgent.add(delegate: self)
        NuguCentralManager.shared.client.audioPlayerAgent.add(displayDelegate: self)
        NuguCentralManager.shared.client.audioPlayerAgent.add(delegate: self)
    }
    
    /// Show nugu usage guide webpage after successful login process
    func showGuideWebIfNeeded() {
        guard hasShownGuideWeb == false,
            let url = SampleApp.makeGuideWebURL(deviceUniqueId: NuguCentralManager.shared.oauthClient.deviceUniqueId) else { return }
        
        performSegue(withIdentifier: "mainToGuideWeb", sender: url)
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
            NuguCentralManager.shared.stopWakeUpDetector()
            
            // Disable Nugu SDK
            NuguCentralManager.shared.disable()
            return
        }
        
        // Exception handling when already connected, scheduled update in future
        nuguButton.isEnabled = true
        nuguButton.isHidden = false
        
        // Enable Nugu SDK
        NuguCentralManager.shared.enable()
        
        refreshWakeUpDetector()
    }
    
    func refreshWakeUpDetector() {
        NuguCentralManager.shared.refreshWakeUpDetector()
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
        voiceChromeDismissWorkItem?.cancel()
        
        NuguAudioSessionManager.shared.requestRecordPermission { [weak self] isGranted in
            guard let self = self else { return }
            guard isGranted else {
                log.error(SampleAppError.recordPermissionError)
                return
            }
            NuguCentralManager.shared.localTTSAgent.stopLocalTTS()
            NuguCentralManager.shared.client.asrAgent.startRecognition(initiator: initiator) { [weak self] (asrResult, _) in
                self?.updateVoiceChrome(asrResult)
            }
            
            self.nuguVoiceChrome.removeFromSuperview()
            self.nuguVoiceChrome = NuguVoiceChrome(frame: CGRect(x: 0, y: self.view.frame.size.height, width: self.view.frame.size.width, height: NuguVoiceChrome.recommendedHeight + SampleApp.bottomSafeAreaHeight))
            self.nuguVoiceChrome.onCloseButtonClick = { [weak self] in
                self?.dismissVoiceChrome()
            }
            self.view.addSubview(self.nuguVoiceChrome)
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: -self.nuguVoiceChrome.bounds.height)
            }
        }
    }
    
    func dismissVoiceChrome() {
        voiceChromeDismissWorkItem?.cancel()
        NuguCentralManager.shared.client.asrAgent.stopRecognition()
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: self.nuguVoiceChrome.bounds.height)
        }, completion: { [weak self] _ in
            self?.nuguVoiceChrome.removeFromSuperview()
        })
    }
    
    private func updateVoiceChrome(_ asrResult: ASRResult) {
        switch asrResult {
        case .complete(let text):
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.setRecognizedText(text: text)
                ASRBeepPlayer.shared.beep(type: .success)
            }
        case .partial(let text):
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.setRecognizedText(text: text)
            }
        case .error(let error):
            DispatchQueue.main.async { [weak self] in
                switch error {
                case ASRError.listenFailed:
                    ASRBeepPlayer.shared.beep(type: .fail)
                    self?.nuguVoiceChrome.changeState(state: .speakingError)
                case ASRError.recognizeFailed:
                    NuguCentralManager.shared.localTTSAgent.playLocalTTS(type: .deviceGatewayRequestUnacceptable)
                default:
                    ASRBeepPlayer.shared.beep(type: .fail)
                }
            }
        default: break
        }
    }
}

// MARK: - Private (DisplayView)

private extension MainViewController {
    func addDisplayView(displayTemplate: DisplayTemplate) -> UIView? {
        displayView?.removeFromSuperview()
        
        switch displayTemplate.type {
        case "Display.FullText1", "Display.FullText2", "Display.FullText3",
             "Display.ImageText1", "Display.ImageText2", "Display.ImageText3", "Display.ImageText4":
            displayView = DisplayBodyView(frame: view.frame)
        case "Display.TextList1", "Display.TextList2",
             "Display.ImageList1", "Display.ImageList2", "Display.ImageList3":
            displayView = DisplayListView(frame: view.frame)
        case "Display.TextList3", "Display.TextList4":
            displayView = DisplayBodyListView(frame: view.frame)
        case "Display.Weather1", "Display.Weather2":
            displayView = DisplayWeatherView(frame: view.frame)
        case "Display.Weather3", "Display.Weather4":
            displayView = DisplayWeatherListView(frame: view.frame)
        default:
            // Draw your own DisplayView with DisplayTemplate.payload and set as self.displayView
            break
        }
        
        guard let displayView = displayView else { return nil }
        
        displayView.displayPayload = displayTemplate.payload
        displayView.onCloseButtonClick = { [weak self] in
            guard let self = self else { return }
            self.dismissDisplayView()
        }
        displayView.onItemSelect = { (selectedItemToken) in
            guard let selectedItemToken = selectedItemToken else { return }
            NuguCentralManager.shared.client.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: selectedItemToken)
        }
        displayView.onUserInteraction = {
            NuguCentralManager.shared.client.displayAgent.notifyUserInteraction()
        }
        displayView.alpha = 0
        view.insertSubview(displayView, belowSubview: nuguButton)
        UIView.animate(withDuration: 0.3) {
            displayView.alpha = 1.0
        }
        
        return displayView
    }
    
    func updateDisplayView(displayTemplate: DisplayTemplate) {
        guard let currentDisplayView = displayView else {
            return
        }
        currentDisplayView.update(updatePayload: displayTemplate.payload)
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
        })
        displayView = nil
    }
}

// MARK: - Private (DisplayAudioPlayerView)

private extension MainViewController {
    func addDisplayAudioPlayerView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate) -> UIView? {
        displayAudioPlayerView?.removeFromSuperview()

        let audioPlayerView = DisplayAudioPlayerView(frame: view.frame)
        audioPlayerView.displayPayload = audioPlayerDisplayTemplate.payload
        audioPlayerView.onCloseButtonClick = { [weak self] in
            guard let self = self else { return }
            self.dismissDisplayAudioPlayerView()
            NuguCentralManager.shared.displayPlayerController?.remove()
        }
        audioPlayerView.onUserInteraction = {
            NuguCentralManager.shared.client.audioPlayerAgent.notifyUserInteraction()
        }
        
        audioPlayerView.alpha = 0
        view.insertSubview(audioPlayerView, belowSubview: nuguButton)
        displayAudioPlayerView = audioPlayerView
        UIView.animate(withDuration: 0.3) {
            audioPlayerView.alpha = 1.0
        }
        
        return audioPlayerView
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
        })
        displayAudioPlayerView = nil
    }
}

// MARK: - WakeUpDetectorDelegate

extension MainViewController: KeywordDetectorDelegate {
    func keywordDetectorDidDetect(data: Data, padding: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.presentVoiceChrome(initiator: .wakeUpKeyword)
        }
    }
    
    func keywordDetectorDidStop() {}
    
    func keywordDetectorStateDidChange(_ state: KeywordDetectorState) {
        switch state {
        case .active:
            DispatchQueue.main.async { [weak self] in
                self?.nuguButton.startListeningAnimation()
            }
        case .inactive:
            DispatchQueue.main.async { [weak self] in
                self?.nuguButton.stopListeningAnimation()
            }
        }
    }
    
    func keywordDetectorDidError(_ error: Error) {}
}

// MARK: - DialogStateDelegate

extension MainViewController: DialogStateDelegate {
    func dialogStateDidChange(_ state: DialogState, expectSpeech: ASRExpectSpeech?) {
        switch state {
        case .idle:
            voiceChromeDismissWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.dismissVoiceChrome()
            })
            guard let voiceChromeDismissWorkItem = voiceChromeDismissWorkItem else { break }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: voiceChromeDismissWorkItem)
        case .speaking:
            DispatchQueue.main.async { [weak self] in
                guard expectSpeech == nil else {
                    self?.nuguVoiceChrome.changeState(state: .speaking)
                    self?.nuguVoiceChrome.minimize()
                    return
                }
                self?.dismissVoiceChrome()
            }
        case .listening:
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.changeState(state: .listeningPassive)
                ASRBeepPlayer.shared.beep(type: .start)
            }
        case .recognizing:
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.changeState(state: .listeningActive)
                self?.nuguVoiceChrome.maximize()
            }
        case .thinking:
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.changeState(state: .processing)
            }
        case .expectingSpeech: break
        }
    }
}

// MARK: - AutomaticSpeechRecognitionDelegate

extension MainViewController: ASRAgentDelegate {
    func asrAgentDidChange(state: ASRState, expectSpeech: ASRExpectSpeech?) {
        switch state {
        case .idle:
            refreshWakeUpDetector()
        case .listening:
            NuguCentralManager.shared.stopWakeUpDetector()
        default:
            break
        }
    }
}

// MARK: - TextAgentDelegate

extension MainViewController: TextAgentDelegate {
    func textAgentShouldHandleTextSource(directive: Downstream.Directive) -> Bool {
        return true
    }
    
    func textAgentDidRequestExpectSpeech() -> ASRExpectSpeech? {
        return NuguCentralManager.shared.client.asrAgent.expectSpeech
    }
}

// MARK: - DisplayAgentDelegate

extension MainViewController: DisplayAgentDelegate {
    func displayAgentFocusedItemToken() -> String? {
        guard let displayControllableView = displayView as? DisplayControllable else {
            return nil
        }
        return displayControllableView.focusedItemToken()
    }
    
    func displayAgentVisibleTokenList() -> [String]? {
        guard let displayControllableView = displayView as? DisplayControllable else {
            return nil
        }
        return displayControllableView.visibleTokenList()
    }
    
    func displayAgentShouldMoveFocus(direction: DisplayControlPayload.Direction) -> Bool {
        guard let displayControllableView = displayView as? DisplayControllable else {
            return false
        }
        return displayControllableView.focus(direction: direction)
    }
    
    func displayAgentShouldScroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let displayControllableView = displayView as? DisplayControllable else {
            return false
        }
        return displayControllableView.scroll(direction: direction)
    }
    
    func displayAgentDidRender(template: DisplayTemplate) -> AnyObject? {
        return addDisplayView(displayTemplate: template)
    }
    
    func displayAgentShouldUpdate(template: DisplayTemplate) {
        updateDisplayView(displayTemplate: template)
    }
    
    func displayAgentShouldClear(template: DisplayTemplate) {
        dismissDisplayView()
    }
}

// MARK: - DisplayPlayerAgentDelegate

extension MainViewController: AudioPlayerDisplayDelegate {
    //TODO: - Should be implemented
    func audioPlayerDisplayShouldShowLyrics() -> Bool { return false }
    
    func audioPlayerDisplayShouldHideLyrics() -> Bool { return false }
    
    func audioPlayerDisplayShouldControlLyricsPage(direction: AudioPlayerDisplayControlPayload.Direction) -> Bool { return false }
    
    func audioPlayerDisplayDidRender(template: AudioPlayerDisplayTemplate) -> AnyObject? {
        NuguCentralManager.shared.displayPlayerController?.nuguAudioPlayerDisplayDidRender(template: template)
        return addDisplayAudioPlayerView(audioPlayerDisplayTemplate: template)
    }
    
    func audioPlayerDisplayShouldClear(template: AudioPlayerDisplayTemplate) {
        NuguCentralManager.shared.displayPlayerController?.nuguAudioPlayerDisplayShouldClear()
        dismissDisplayAudioPlayerView()
    }
    
    func audioPlayerDisplayShouldUpdateMetadata(payload: String) {
        guard let displayAudioPlayerView = displayAudioPlayerView else {
            return
        }
        displayAudioPlayerView.updateSettings(payload: payload)
    }
}

// MARK: - AudioPlayerAgentDelegate

extension MainViewController: AudioPlayerAgentDelegate {
    func audioPlayerAgentDidChange(state: AudioPlayerState, dialogRequestId: String) {
        NuguCentralManager.shared.displayPlayerController?.nuguAudioPlayerAgentDidChange(state: state)
        switch state {
        case .paused, .playing:
            NuguAudioSessionManager.shared.observeAVAudioSessionInterruptionNotification()
        case .idle, .finished, .stopped:
            NuguAudioSessionManager.shared.removeObservingAVAudioSessionInterruptionNotification()
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                let displayAudioPlayerView = self.displayAudioPlayerView else { return }
            displayAudioPlayerView.audioPlayerState = state
        }
    }
}
