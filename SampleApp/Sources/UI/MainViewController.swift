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
    private lazy var displayWebViewPresenter: DisplayWebViewPresenter = {
        DisplayWebViewPresenter(
            viewController: self,
            nuguClient: NuguCentralManager.shared.client,
            clientInfo: ["buttonColor": "white"]
        )
    }()
    private lazy var audioDisplayViewPresenter: AudioDisplayViewPresenter = {
        AudioDisplayViewPresenter(
            viewController: self,
            nuguClient: NuguCentralManager.shared.client
        )
    }()
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var asrStateObserver: Any?
    private var asrResultObserver: Any?
    private var dialogStateObserver: Any?
    
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
        resignActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main, using: { (_) in
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
        becomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: { [weak self] (_) in
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
        presentVoiceChrome(initiator: .tap)
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
        
        // set delegate
        NuguCentralManager.shared.client.keywordDetector.delegate = self
        
        // Observers
        addAsrAgentObserver(NuguCentralManager.shared.client.asrAgent)
        addDialogStateObserver(NuguCentralManager.shared.client.dialogStateAggregator)
        
        // UI
        voiceChromePresenter.delegate = self
        displayWebViewPresenter.delegate = self
        audioDisplayViewPresenter.delegate = self
        nuguVoiceChrome.onChipsSelect = { [weak self] selectedChips in
            self?.chipsDidSelect(selectedChips: selectedChips)
        }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapForStopRecognition))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    /// Show nugu usage guide webpage after successful login process
    func showGuideWebIfNeeded() {
        guard UserDefaults.Standard.hasSeenGuideWeb == false else { return }
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

// MARK: - DisplayWebViewPresenterDelegate

extension MainViewController: DisplayWebViewPresenterDelegate {    
    func onDisplayWebViewNuguButtonClick() {
        presentVoiceChrome(initiator: .tap)
    }
}

// MARK: - AudioDisplayViewPresenterDelegate

extension MainViewController: AudioDisplayViewPresenterDelegate {
    func displayControllerShouldUpdateTemplate(template: AudioPlayerDisplayTemplate) {
        NuguCentralManager.shared.displayPlayerController.update(template)
    }
    
    func displayControllerShouldUpdateState(state: AudioPlayerState) {
        NuguCentralManager.shared.displayPlayerController.update(state)
    }
    
    func displayControllerShouldUpdateDuration(duration: Int) {
        NuguCentralManager.shared.displayPlayerController.update(duration)
    }
    
    func displayControllerShouldRemove() {
        NuguCentralManager.shared.displayPlayerController.remove()
    }
    
    func onAudioDisplayViewNuguButtonClick() {
        presentVoiceChrome(initiator: .tap)
    }
    
    func onAudioDisplayViewChipsSelect(selectedChips: NuguChipsButton.NuguChipsButtonType?) {
        chipsDidSelect(selectedChips: selectedChips)
    }
}

// MARK: - KeywordDetectorDelegate

extension MainViewController: KeywordDetectorDelegate {
    func keywordDetectorDidDetect(keyword: String?, data: Data, start: Int, end: Int, detection: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.presentVoiceChrome(initiator: .wakeUpWord(
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

// MARK: - Observers

private extension MainViewController {
    func addAsrAgentObserver(_ object: ASRAgentProtocol) {
        asrStateObserver = notificationCenter.addObserver(forName: .asrAgentStateDidChange, object: object, queue: .main) { (notification) in
            guard let state = notification.userInfo?[ASRAgent.ObservingFactor.State.state] as? ASRState else { return }
            
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
        
        asrResultObserver = notificationCenter.addObserver(forName: .asrAgentResultDidReceive, object: object, queue: .main) { (notification) in
            guard let result = notification.userInfo?[ASRAgent.ObservingFactor.Result.result] as? ASRResult else { return }
            
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
    
    func addDialogStateObserver(_ object: DialogStateAggregator) {
        dialogStateObserver = notificationCenter.addObserver(forName: .dialogStateDidChange, object: object, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            guard let state = notification.userInfo?[DialogStateAggregator.ObservingFactor.State.state] as? DialogState,
                  let isMultiturn = notification.userInfo?[DialogStateAggregator.ObservingFactor.State.multiturn] as? Bool else { return }
            
            let chips = notification.userInfo?[DialogStateAggregator.ObservingFactor.State.chips] as? [ChipsAgentItem.Chip]
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
}
