//
//  MainViewController.swift
//  SampleApp-iOS
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

import NuguInterface
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
            selector: #selector(didEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
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
    
    /// Catch entering background notification to disable nugu service
    /// It is possible to keep connected even on background, but need careful attention for battery issues, audio interruptions and so on
    /// - Parameter notification: UIApplication.didBecomeActiveNotification
    func didEnterBackground(_ notification: Notification) {
        NuguCentralManager.shared.disable()
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
        presentVoiceChrome()
    }
}

// MARK: - Private (Nugu)

private extension MainViewController {
    
    /// Initialize to start using Nugu
    /// AudioSession is required for using Nugu
    /// Add delegates for all the components that provided by default client or custom provided ones
    func initializeNugu() {
        // Set AudioSession
        NuguAudioSessionManager.allowMixWithOthers()
        
        // Add delegates
        NuguCentralManager.shared.client.networkManager.add(statusDelegate: self)
        
        NuguCentralManager.shared.client.wakeUpDetector?.delegate = self
        
        NuguCentralManager.shared.client.dialogStateAggregator.add(delegate: self)
        NuguCentralManager.shared.client.asrAgent?.add(delegate: self)
        NuguCentralManager.shared.client.textAgent?.add(delegate: self)
        
        NuguCentralManager.shared.client.displayAgent?.add(delegate: self)
        
        NuguCentralManager.shared.client.audioPlayerAgent?.add(displayDelegate: self)
        NuguCentralManager.shared.client.audioPlayerAgent?.add(delegate: self)

        NuguCentralManager.shared.displayPlayerController.use()
    }
    
    /// Show nugu usage guide webpage after successful login process
    func showGuideWebIfNeeded() {
        guard hasShownGuideWeb == false,
            let url = SampleApp.guideWebUrl else { return }
        
        performSegue(withIdentifier: "mainToGuideWeb", sender: url)
    }
    
    /// Refresh Nugu status
    /// Connect or disconnect Nugu service by circumstance
    /// Hide Nugu button when Nugu service is intended not to use or network issue has occured
    /// Disable Nugu button when wake up feature is intended not to use
    func refreshNugu() {
        switch UserDefaults.Standard.useNuguService {
        case true:
            // Exception handling when already connected, scheduled update in future
            guard NuguCentralManager.shared.client.networkManager.connected == false else {
                nuguButton.isEnabled = true
                nuguButton.isHidden = false
                
                refreshWakeUpDetector()
                return
            }
            
            // Enable Nugu SDK
            NuguCentralManager.shared.enable(accessToken: UserDefaults.Standard.accessToken ?? "")
        case false:
            // Exception handling when already disconnected, scheduled update in future
            guard NuguCentralManager.shared.client.networkManager.connected == true else {
                nuguButton.isEnabled = false
                nuguButton.isHidden = true
                
                NuguCentralManager.shared.stopWakeUpDetector()
                return
            }
            
            // Disable Nugu SDK
            NuguCentralManager.shared.disable()
        }
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
    func presentVoiceChrome() {
        voiceChromeDismissWorkItem?.cancel()
        NuguCentralManager.shared.startRecognize()
        
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
    func addDisplayView(displayTemplate: DisplayTemplate) {
        displayView?.removeFromSuperview()
        
        switch displayTemplate.type {
        case "Display.FullText1", "Display.FullText2",
             "Display.ImageText1", "Display.ImageText2", "Display.ImageText3", "Display.ImageText4":
            displayView = DisplayBodyView(frame: view.frame)
        case "Display.TextList1", "Display.TextList2",
             "Display.ImageList1", "Display.ImageList2", "Display.ImageList3":
            displayView = DisplayListView(frame: view.frame)
        case "Display.TextList3", "Display.TextList4":
            displayView = DisplayBodyListView(frame: view.frame)
        default:
            // Draw your own DisplayView with DisplayTemplate.payload and set as self.displayView
            break
        }
        
        guard let displayView = displayView else { return }
        
        displayView.displayPayload = displayTemplate.payload
        displayView.onCloseButtonClick = { [weak self] in
            guard let self = self else { return }
            NuguCentralManager.shared.client.displayAgent?.clearDisplay(delegate: self)
            self.dismissDisplayView()
        }
        displayView.onItemSelect = { (selectedItemToken) in
            guard let selectedItemToken = selectedItemToken else { return }
            NuguCentralManager.shared.client.displayAgent?.elementDidSelect(templateId: displayTemplate.templateId, token: selectedItemToken)
        }
        displayView.alpha = 0
        view.insertSubview(displayView, belowSubview: nuguButton)
        UIView.animate(withDuration: 0.3) {
            displayView.alpha = 1.0
        }
    }
    
    func dismissDisplayView() {
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
    func addDisplayAudioPlayerView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate) {
        displayAudioPlayerView?.removeFromSuperview()
        
        switch audioPlayerDisplayTemplate.typeInfo {
        case .audioPlayer(let item):
            let audioPlayerView = DisplayAudioPlayerView(frame: view.frame)
            audioPlayerView.displayItem = item
            audioPlayerView.onCloseButtonClick = { [weak self] in
                guard let self = self else { return }
                NuguCentralManager.shared.client.audioPlayerAgent?.clearDisplay(displayDelegate: self)
                self.dismissDisplayAudioPlayerView()
            }
            displayAudioPlayerView = audioPlayerView
        }
        guard let displayAudioPlayerView = displayAudioPlayerView else { return }
        view.insertSubview(displayAudioPlayerView, belowSubview: nuguButton)
    }
    
    func dismissDisplayAudioPlayerView() {
        displayAudioPlayerView?.removeFromSuperview()
        displayAudioPlayerView = nil
    }
}

// MARK: - NetworkStatusDelegate

extension MainViewController: NetworkStatusDelegate {
    func networkStatusDidChange(_ status: NetworkStatus) {
        switch status {
        case .connected:
            // Refresh wakeup-detector
            refreshWakeUpDetector()
            
            // Update UI
            DispatchQueue.main.async { [weak self] in
                self?.nuguButton.isEnabled = true
                self?.nuguButton.isHidden = false
            }
        case .disconnected(let networkError):
            switch networkError {
            case .authError:
                DispatchQueue.main.async {
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                        let rootNavigationViewController = appDelegate.window?.rootViewController as? UINavigationController else { return }
                    NuguToastManager.shared.showToast(message: "누구 앱과의 연결이 해제되었습니다. 다시 연결해주세요.")
                    NuguCentralManager.shared.disable()
                    UserDefaults.Standard.clear()
                    rootNavigationViewController.popToRootViewController(animated: true)
                }
            default:
                // Stop wakeup-detector
                NuguCentralManager.shared.stopWakeUpDetector()
                
                // Update UI
                DispatchQueue.main.async { [weak self] in
                    self?.nuguButton.isEnabled = false
                    if UserDefaults.Standard.useNuguService == true {
                        self?.nuguButton.isHidden = false
                    } else {
                        self?.nuguButton.isHidden = true
                    }
                }
            }
        }
    }
}

// MARK: - WakeUpDetectorDelegate

extension MainViewController: WakeUpDetectorDelegate {
    func wakeUpDetectorDidDetect() {
        DispatchQueue.main.async { [weak self] in
            self?.presentVoiceChrome()
        }
    }
    
    func wakeUpDetectorDidStop() {}
    
    func wakeUpDetectorStateDidChange(_ state: WakeUpDetectorState) {
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
    
    func wakeUpDetectorDidError(_ error: Error) {}
}

// MARK: - DialogStateDelegate

extension MainViewController: DialogStateDelegate {
    func dialogStateDidChange(_ state: DialogState) {
        switch state {
        case .idle:
            voiceChromeDismissWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.dismissVoiceChrome()
            })
            guard let voiceChromeDismissWorkItem = voiceChromeDismissWorkItem else { break }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: voiceChromeDismissWorkItem)
        case .speaking(let expectingSpeech):
            DispatchQueue.main.async { [weak self] in
                guard expectingSpeech == false else {
                    self?.nuguVoiceChrome.changeState(state: .speaking)
                    self?.nuguVoiceChrome.minimize()
                    return
                }
                self?.dismissVoiceChrome()
            }
        case .listening:
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.changeState(state: .listeningPassive)
                SoundPlayer.playSound(soundType: .start)
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
    func asrAgentDidChange(state: ASRState) {
        switch state {
        case .idle:
            refreshWakeUpDetector()
        case .listening:
            NuguCentralManager.shared.stopWakeUpDetector()
        default:
            break
        }
    }
    
    func asrAgentDidReceive(result: ASRResult) {
        switch result {
        case .complete(let text):
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.setRecognizedText(text: text)
                SoundPlayer.playSound(soundType: .success)
            }
        case .partial(let text):
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.setRecognizedText(text: text)
            }
        case .error(let asrError):
            DispatchQueue.main.async { [weak self] in
                SoundPlayer.playSound(soundType: .fail)
                switch asrError {
                case .listenFailed, .recognizeFailed:
                    self?.nuguVoiceChrome.changeState(state: .speakingError)
                default: break
                }
            }
        default: break
        }
    }
}

// MARK: - TextAgentDelegate

extension MainViewController: TextAgentDelegate {
    func textAgentDidReceive(result: TextAgentResult) {
        switch result {
        case .complete:
            DispatchQueue.main.async {
                SoundPlayer.playSound(soundType: .success)
            }
        case .error(let textAgentError):
            switch textAgentError {
            case .responseTimeout:
                DispatchQueue.main.async {
                    SoundPlayer.playSound(soundType: .fail)
                }
            }
        }
    }
}

// MARK: - DisplayAgentDelegate

extension MainViewController: DisplayAgentDelegate {
    func displayAgentShouldRender(template: DisplayTemplate) -> Bool {
        return true
    }
    
    func displayAgentDidRender(template: DisplayTemplate) {
        DispatchQueue.main.async { [weak self] in
            self?.addDisplayView(displayTemplate: template)
        }   
    }
    
    func displayAgentShouldClear(template: DisplayTemplate) -> Bool {
        return true
    }
    
    func displayAgentDidClear(template: DisplayTemplate) {
        DispatchQueue.main.async { [weak self] in
            self?.dismissDisplayView()
        }
    }
}

// MARK: - DisplayPlayerAgentDelegate

extension MainViewController: AudioPlayerDisplayDelegate {
    func audioPlayerDisplayShouldRender(template: AudioPlayerDisplayTemplate) -> Bool {
        return true
    }
    
    func audioPlayerDisplayDidRender(template: AudioPlayerDisplayTemplate) {
        DispatchQueue.main.async { [weak self] in
            self?.addDisplayAudioPlayerView(audioPlayerDisplayTemplate: template)
        }
    }
    
    func audioPlayerDisplayShouldClear(template: AudioPlayerDisplayTemplate) -> Bool {
        return true
    }
    
    func audioPlayerDisplayDidClear(template: AudioPlayerDisplayTemplate) {
        DispatchQueue.main.async { [weak self] in
            self?.dismissDisplayAudioPlayerView()
        }
    }
}

// MARK: - AudioPlayerAgentDelegate

extension MainViewController: AudioPlayerAgentDelegate {
    func audioPlayerAgentDidChange(state: AudioPlayerState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                let displayAudioPlayerView = self.displayAudioPlayerView else { return }
            displayAudioPlayerView.audioPlayerState = state
        }
    }
}
