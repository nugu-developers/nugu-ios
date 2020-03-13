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
    
    private var displayContextReleaseTimer: DispatchSourceTimer?
    private let displayContextReleaseTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.MainViewController.displayContextReleaseTimer")
    
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
        
        // TODO: network status를 sdk로부터 전달받을 수 없음.
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(networkStatusDidChange(_:)),
//            name: .nuguClientNetworkStatus,
//            object: nil
//        )
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
        NuguCentralManager.shared.client.textAgent.add(delegate: self)
        NuguCentralManager.shared.client.displayAgent.add(delegate: self)
        NuguCentralManager.shared.client.audioPlayerAgent.add(displayDelegate: self)
        NuguCentralManager.shared.client.audioPlayerAgent.add(delegate: self)

        NuguCentralManager.shared.displayPlayerController?.use()
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
        refreshWakeUpDetector()
        
        // Enable Nugu SDK
        NuguCentralManager.shared.enable()
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
        NuguCentralManager.shared.startRecognize(initiator: initiator)
        
        nuguVoiceChrome.removeFromSuperview()
        nuguVoiceChrome = NuguVoiceChrome(frame: CGRect(x: 0, y: view.frame.size.height, width: view.frame.size.width, height: NuguVoiceChrome.recommendedHeight + SampleApp.bottomSafeAreaHeight))
        nuguVoiceChrome.onCloseButtonClick = { [weak self] in
            self?.dismissVoiceChrome()
        }
        view.addSubview(nuguVoiceChrome)
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.nuguVoiceChrome.frame = CGRect(x: 0, y: self.view.frame.size.height - (NuguVoiceChrome.recommendedHeight + SampleApp.bottomSafeAreaHeight), width: self.view.frame.size.width, height: 256 + SampleApp.bottomSafeAreaHeight)
        }
    }
    
    func dismissVoiceChrome() {
        voiceChromeDismissWorkItem?.cancel()
        NuguCentralManager.shared.stopRecognize()
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.nuguVoiceChrome.frame = CGRect(x: 0, y: self.view.frame.size.height + SampleApp.bottomSafeAreaHeight, width: self.view.frame.size.width, height: NuguVoiceChrome.recommendedHeight + SampleApp.bottomSafeAreaHeight)
        }, completion: { [weak self] _ in
            self?.nuguVoiceChrome.removeFromSuperview()
        })
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
        displayView.onUserInteraction = { [weak self] in
            guard let self = self else { return }
            self.startDisplayContextReleaseTimer(templateId: displayTemplate.templateId, duration: displayTemplate.duration.time)
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
        stopDisplayContextReleaseTimer()
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.displayView?.alpha = 0
            },
            completion: { [weak self] _ in
                self?.displayView?.removeFromSuperview()
                self?.displayView = nil
        })
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

        view.insertSubview(audioPlayerView, belowSubview: nuguButton)
        displayAudioPlayerView = audioPlayerView
        
        return audioPlayerView
    }
    
    func dismissDisplayAudioPlayerView() {
        displayAudioPlayerView?.removeFromSuperview()
        displayAudioPlayerView = nil
    }
}

// MARK: - Private (DisplayTimer)

private extension MainViewController {
    func startDisplayContextReleaseTimer(templateId: String, duration: DispatchTimeInterval) {
        // Inform sdk to stop displayRendering timer
        NuguCentralManager.shared.client.displayAgent.stopRenderingTimer(templateId: templateId)
        
        // Start application side's displayContextReleaseTimer
        displayContextReleaseTimer?.cancel()
        displayContextReleaseTimer = DispatchSource.makeTimerSource(queue: displayContextReleaseTimerQueue)
        displayContextReleaseTimer?.schedule(deadline: .now() + duration)
        displayContextReleaseTimer?.setEventHandler(handler: {
            DispatchQueue.main.async { [weak self] in
                self?.dismissDisplayView()
            }
        })
        displayContextReleaseTimer?.resume()
    }
    
    func stopDisplayContextReleaseTimer() {
        displayContextReleaseTimer?.cancel()
        displayContextReleaseTimer = nil
    }
}

// TODO: network status를 nugu sdk로부터 전달받을 수 없음.
// MARK: - NuguNetworkStatus
//
//extension MainViewController {
//    @objc func networkStatusDidChange(_ notification: Notification) {
//        guard let status = notification.userInfo?["status"] as? NetworkStatus else {
//            return
//        }
//
//        switch status {
//        case .connected:
//            // Refresh wakeup-detector
//            refreshWakeUpDetector()
//
//            // Update UI
//            DispatchQueue.main.async { [weak self] in
//                self?.nuguButton.isEnabled = true
//                self?.nuguButton.isHidden = false
//            }
//        case .disconnected(let error):
//            // Stop wakeup-detector
//            NuguCentralManager.shared.stopWakeUpDetector()
//
//            // Update UI
//            DispatchQueue.main.async { [weak self] in
//                self?.nuguButton.isEnabled = false
//                if UserDefaults.Standard.useNuguService == true {
//                    self?.nuguButton.isHidden = false
//                } else {
//                    self?.nuguButton.isHidden = true
//                }
//            }
//
//            // Handle Nugu's predefined NetworkError
//            if let networkError = error as? NetworkError {
//                switch networkError {
//                case .authError:
//                    NuguCentralManager.shared.handleAuthError()
//                case .timeout:
//                    NuguCentralManager.shared.localTTSAgent.playLocalTTS(type: .deviceGatewayTimeout)
//                default:
//                    NuguCentralManager.shared.localTTSAgent.playLocalTTS(type: .deviceGatewayAuthServerError)
//                }
//            } else { // Handle URLError
//                guard let urlError = error as? URLError else { return }
//                switch urlError.code {
//                case .networkConnectionLost, .notConnectedToInternet: // In unreachable network status, play prepared local tts (deviceGatewayNetworkError)
//                    NuguCentralManager.shared.localTTSAgent.playLocalTTS(type: .deviceGatewayNetworkError)
//                default: // Handle other URLErrors with your own way
//                    break
//                }
//            }
//        }
//    }
//}

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
    
    func asrAgentDidReceive(result: ASRResult, dialogRequestId: String) {
        switch result {
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

// MARK: - TextAgentDelegate

extension MainViewController: TextAgentDelegate {
    func textAgentDidReceive(result: Result<Void, Error>, dialogRequestId: String) {
        switch result {
        case .success:
            DispatchQueue.main.async {
                ASRBeepPlayer.shared.beep(type: .success)
            }
        case .failure:
            DispatchQueue.main.async {
                ASRBeepPlayer.shared.beep(type: .fail)
            }
        }
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
    
    func displayAgentShouldClear(template: DisplayTemplate, reason: DisplayTemplate.ClearReason) {
        switch reason {
        case .timer:
            dismissDisplayView()
        case .directive:
            dismissDisplayView()
        }
    }
}

// MARK: - DisplayPlayerAgentDelegate

extension MainViewController: AudioPlayerDisplayDelegate {
    //TODO: - Should be implemented
    func audioPlayerDisplayShouldShowLyrics() -> Bool { return false }
    
    func audioPlayerDisplayShouldHideLyrics() -> Bool { return false }
    
    func audioPlayerDisplayShouldControlLyricsPage(direction: String) -> Bool { return false }
    
    func audioPlayerDisplayDidRender(template: AudioPlayerDisplayTemplate) -> AnyObject? {
        return addDisplayAudioPlayerView(audioPlayerDisplayTemplate: template)
    }
    
    func audioPlayerDisplayShouldClear(template: AudioPlayerDisplayTemplate, reason: AudioPlayerDisplayTemplate.ClearReason) {
        switch reason {
        case .timer:
            dismissDisplayAudioPlayerView()
        case .directive:
            dismissDisplayAudioPlayerView()
        }
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
    func audioPlayerAgentDidChange(state: AudioPlayerState) {
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
