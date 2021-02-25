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

import NuguAgents
import NuguClientKit
import NuguUIKit

final class MainViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet private weak var nuguButton: NuguButton!
    @IBOutlet private weak var settingButton: UIButton!
    
    private lazy var voiceChromePresenter = VoiceChromePresenter(
        viewController: self,
        nuguClient: NuguCentralManager.shared.client
    )
    private lazy var displayWebViewPresenter = DisplayWebViewPresenter(
        viewController: self,
        nuguClient: NuguCentralManager.shared.client,
        clientInfo: ["buttonColor": "white"]
    )
    private lazy var audioDisplayViewPresenter = AudioDisplayViewPresenter(
        viewController: self,
        nuguClient: NuguCentralManager.shared.client
    )
    
    // MARK: Observers

    private let notificationCenter = NotificationCenter.default
    private var resignActiveObserver: Any?
    private var becomeActiveObserver: Any?
    private var asrResultObserver: Any?
    private var dialogStateObserver: Any?
    
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        NuguCentralManager.shared.stopListening()
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
        if let asrResultObserver = asrResultObserver {
            notificationCenter.removeObserver(asrResultObserver)
        }
        
        if let dialogStateObserver = dialogStateObserver {
            notificationCenter.removeObserver(dialogStateObserver)
        }
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
            NuguCentralManager.shared.stopListening()
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

// MARK: - Private (IBAction)

private extension MainViewController {
    @IBAction func showSettingsButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.stopListening()

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
        // keyword detector delegate
        NuguCentralManager.shared.client.keywordDetector.delegate = self
        
        // Observers
        addAsrAgentObserver(NuguCentralManager.shared.client.asrAgent)
        addDialogStateObserver(NuguCentralManager.shared.client.dialogStateAggregator)
        
        // UI
        voiceChromePresenter.delegate = self
        displayWebViewPresenter.delegate = self
        audioDisplayViewPresenter.delegate = self
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

// MARK: - Private (Voice Chrome)

private extension MainViewController {
    func presentVoiceChrome(initiator: ASRInitiator) {
        do {
            try voiceChromePresenter.presentVoiceChrome(chipsData: [
                NuguChipsButton.NuguChipsButtonType.normal(text: "오늘 몇일이야", token: nil)
            ])
            NuguCentralManager.shared.startListening(initiator: initiator)
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

// MARK: - DisplayWebViewPresenterDelegate

extension MainViewController: DisplayWebViewPresenterDelegate {    
    func onDisplayWebViewNuguButtonClick() {
        presentVoiceChrome(initiator: .user)
    }
}

// MARK: - AudioDisplayViewPresenterDelegate

extension MainViewController: AudioDisplayViewPresenterDelegate {    
    func onAudioDisplayViewNuguButtonClick() {
        presentVoiceChrome(initiator: .user)
    }
    
    func onAudioDisplayViewChipsSelect(selectedChips: NuguChipsButton.NuguChipsButtonType?) {
        chipsDidSelect(selectedChips: selectedChips)
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
    
    func voiceChromeChipsDidClick(chips: NuguChipsButton.NuguChipsButtonType) {
        chipsDidSelect(selectedChips: chips)
    }
}

// MARK: - Observers

private extension MainViewController {
    func addAsrAgentObserver(_ object: ASRAgentProtocol) {
        asrResultObserver = object.observe(NuguAgentNotification.ASR.Result.self, queue: .main) { (notification) in
            switch notification.result {
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
        dialogStateObserver = object.observe(NuguClientNotification.DialogState.State.self, queue: nil) { [weak self] (notification) in
            log.debug("dialog satate: \(notification.state), multiTurn: \(notification.multiTurn), chips: \(notification.chips.debugDescription)")

            switch notification.state {
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
