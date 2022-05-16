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
import AVFoundation

import NuguAgents
import NuguClientKit
import NuguUIKit

final class MainViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet private weak var nuguButton: NuguButton!
    
    private lazy var voiceChromePresenter = VoiceChromePresenter(
        viewController: self,
        nuguClient: NuguCentralManager.shared.client,
        themeController: NuguCentralManager.shared.themeController
    )
    private lazy var displayWebViewPresenter = DisplayWebViewPresenter(
        viewController: self,
        nuguClient: NuguCentralManager.shared.client,
        clientInfo: ["buttonColor": "white"],
        themeController: NuguCentralManager.shared.themeController
    )
    private lazy var audioDisplayViewPresenter = AudioDisplayViewPresenter(
        viewController: self,
        nuguClient: NuguCentralManager.shared.client,
        themeController: NuguCentralManager.shared.themeController,
        options: .all
    )
    
    // MARK: Observers

    private let notificationCenter = NotificationCenter.default
    private var resignActiveObserver: Any?
    private var becomeActiveObserver: Any?
    private var nuguServiceStateObserver: Any?
    private var speechStateObserver: Any?
    private var dialogStateObserver: Any?

    // MARK: Override
    
    // Support landscape UI for iPad
    override public var traitCollection: UITraitCollection {
        if UIDevice.current.userInterfaceIdiom == .pad && UIDevice.current.orientation.isLandscape {
            return UITraitCollection(traitsFrom: [
                UITraitCollection(horizontalSizeClass: .unspecified),
                                        UITraitCollection(verticalSizeClass: .compact)
            ])
        }
        return super.traitCollection
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeNugu()
        registerObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NuguCentralManager.shared.refreshNugu()
        
        voiceChromePresenter.isStartBeepEnabled = UserDefaults.Standard.useAsrStartSound
        voiceChromePresenter.isSuccessBeepEnabled = UserDefaults.Standard.useAsrSuccessSound
        voiceChromePresenter.isFailBeepEnabled = UserDefaults.Standard.useAsrFailSound
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
            guard let guideWebViewController = segue.destination as? GuideWebViewController else { return }
            guideWebViewController.initialURLString = sender as? String
            
            UserDefaults.Standard.hasSeenGuideWeb = true
        default:
            return
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard UserDefaults.Standard.theme == SampleApp.Theme.system.rawValue else { return }
        NuguCentralManager.shared.themeController.theme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch NuguCentralManager.shared.themeController.theme {
        case .dark:
            return .lightContent
        case .light:
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                return .default
            }
        }
    }
    
    // MARK: Deinitialize
    
    deinit {
        removeObservers()
    }
}

// MARK: - Internal (Voice Chrome)

extension MainViewController {
    func presentVoiceChrome(initiator: ASRInitiator? = nil) {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            NuguToast.shared.showToast(message: "설정에서 마이크 접근 권한을 허용 후 이용하실 수 있습니다.")
            return
        }
        do {
            try voiceChromePresenter.presentVoiceChrome(chipsData: [
                NuguChipsButton.NuguChipsButtonType.normal(text: "오늘 며칠이야", token: nil)
            ])
            
            if let initiator = initiator {
                NuguCentralManager.shared.startListening(initiator: initiator)
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

// MARK: - private (Observer)

private extension MainViewController {
    func registerObservers() {
        // To avoid duplicated observing
        removeObservers()
        
        /**
         Catch resigning active notification to stop recognizing & wake up detector
         It is possible to keep on listening even on background, but need careful attention for battery issues, audio interruptions and so on
         */
        resignActiveObserver = notificationCenter.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main, using: { (_) in
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
        becomeActiveObserver = notificationCenter.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: { [weak self] (_) in
            guard let self = self else { return }
            guard self.navigationController?.visibleViewController == self else { return }

            NuguCentralManager.shared.refreshNugu()
        })
        
        /**
         Observe nugu service state change for NuguButton appearance
         */
        nuguServiceStateObserver = notificationCenter.addObserver(forName: .nuguServiceStateDidChangeNotification, object: nil, queue: .main, using: { [weak self] (notification) in
            guard let self = self,
                  let isEnabled = notification.userInfo?["isEnabled"] as? Bool else { return }
            if isEnabled == true {
                self.nuguButton.isEnabled = true
                self.nuguButton.isHidden = false
            } else {
                self.nuguButton.isEnabled = false
                self.nuguButton.isHidden = true
            }
        })
        
        /**
         Observe speech state change for NuguButton animation
         */
        speechStateObserver = notificationCenter.addObserver(forName: .speechStateDidChangeNotification, object: nil, queue: .main, using: { [weak self] (notification) in
            guard let self = self,
                  let state = notification.userInfo?["state"] as? SpeechRecognizerAggregatorState else { return }
            switch state {
            case .wakeupTriggering:
                self.nuguButton.startFlipAnimation()
            case .cancelled:
                self.nuguButton.stopFlipAnimation()
            case .wakeup(let initiator):
                self.presentVoiceChrome(initiator: initiator)
            case .error(let error):
                log.error("speechState error: \(error)")
                if case SpeechRecognizerAggregatorError.cannotOpenMicInputForWakeup = error {
                    self.nuguButton.stopFlipAnimation()
                } else if case SpeechRecognizerAggregatorError.cannotOpenMicInputForRecognition = error {
                    NuguToast.shared.showToast(message: "음성 인식을 위한 마이크를 사용할 수 없습니다.")
                }
            default:
                break
            }
        })
        
        /**
         Observe dialog state change for NuguButton pauseDeactivation (when thinking state)
         */
        dialogStateObserver = notificationCenter.addObserver(forName: .dialogStateDidChangeNotification, object: nil, queue: .main, using: { [weak self] (notification) in
            guard let self = self,
                  let state = notification.userInfo?["state"] as? DialogState else { return }
            switch state {
            case .thinking:
                self.nuguButton.pauseDeactivateAnimation()
            default:
                break
            }
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
        
        if let nuguServiceStateObserver = nuguServiceStateObserver {
            NotificationCenter.default.removeObserver(nuguServiceStateObserver)
            self.nuguServiceStateObserver = nil
        }
        
        if let speechStateObserver = speechStateObserver {
            NotificationCenter.default.removeObserver(speechStateObserver)
            self.speechStateObserver = nil
        }
        
        if let dialogStateObserver = dialogStateObserver {
            NotificationCenter.default.removeObserver(dialogStateObserver)
            self.dialogStateObserver = nil
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
        presentVoiceChrome(initiator: .tap)
    }
    
    @IBAction func sidOptionSwitchValueChanged(_ optionSwitch: UISwitch) {
        if optionSwitch.isOn == true {
            NuguCentralManager.shared.client.startReceiveServerInitiatedDirective { state in
                log.debug(state)
            }
        } else {
            NuguCentralManager.shared.client.stopReceiveServerInitiatedDirective()
        }
    }
}

// MARK: - Private (Nugu)

private extension MainViewController {
    /// Add delegates for all the components that provided by default client or custom provided ones
    func initializeNugu() {
        // UI
        voiceChromePresenter.delegate = self
        displayWebViewPresenter.delegate = self
        audioDisplayViewPresenter.delegate = self
        
        applyTheme()
    }
    
    /// Apply theme
    func applyTheme() {
        switch SampleApp.Theme(rawValue: UserDefaults.Standard.theme) {
        case .system:
            NuguCentralManager.shared.themeController.theme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        case .light:
            NuguCentralManager.shared.themeController.theme = .light
        case .dark:
            NuguCentralManager.shared.themeController.theme = .dark
        default: break
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    /// Show nugu usage guide webpage after successful login process
    func showGuideWebIfNeeded() {
        guard UserDefaults.Standard.hasSeenGuideWeb == false else { return }
        
        ConfigurationStore.shared.usageGuideUrl(deviceUniqueId: NuguCentralManager.shared.oauthClient.deviceUniqueId) { [weak self] (result) in
            switch result {
            case .success(let urlString):
                DispatchQueue.main.async { [weak self] in
                    self?.performSegue(withIdentifier: "mainToGuideWeb", sender: urlString)
                }
            case .failure(let error):
                log.error(error)
            }
        }
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
    func onAudioDisplayViewNuguButtonClick() {
        presentVoiceChrome(initiator: .tap)
    }
    
    func onAudioDisplayViewChipsSelect(selectedChips: NuguChipsButton.NuguChipsButtonType?) {
        NuguCentralManager.shared.chipsDidSelect(selectedChips: selectedChips)
    }
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
        NuguCentralManager.shared.chipsDidSelect(selectedChips: chips)
    }
    
    func voiceChromeDidReceiveRecognizeError() {
        NuguCentralManager.shared.localTTSAgent.playLocalTTS(type: .deviceGatewayRequestUnacceptable)
    }
}
