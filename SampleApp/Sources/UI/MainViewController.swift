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
    @IBOutlet private weak var textInputTextField: UITextField!
    
    private var voiceChromeDismissWorkItem: DispatchWorkItem?
    
    private weak var displayView: DisplayView?
    private weak var displayAudioPlayerView: AudioDisplayView?
    
    private var nuguVoiceChrome = NuguVoiceChrome()
    
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
        // if tts is playing for multiturn, tts and associated jobs should be stopped when resign active
        if NuguCentralManager.shared.client.dialogStateAggregator.isMultiturn == true {
            NuguCentralManager.shared.client.ttsAgent.stopTTS()
        }
        NuguCentralManager.shared.client.asrAgent.stopRecognition()
        NuguCentralManager.shared.stopMicInputProvider()
    }
    
    /// Catch becoming active notification to refresh mic status & Nugu button
    /// Recover all status for any issues caused from becoming background
    /// - Parameter notification: UIApplication.didBecomeActiveNotification
    func didBecomeActive(_ notification: Notification) {
        guard navigationController?.visibleViewController == self else { return }
        refreshNugu()
    }
        
    func didTapForDismissVoiceChrome() {
        guard nuguVoiceChrome.currentState == .listeningPassive || nuguVoiceChrome.currentState == .listeningActive  else { return }
        dismissVoiceChrome()
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
        NuguCentralManager.shared.client.textAgent.delegate = self
        NuguCentralManager.shared.client.displayAgent.delegate = self
        NuguCentralManager.shared.client.audioPlayerAgent.displayDelegate = self
        NuguCentralManager.shared.client.audioPlayerAgent.add(delegate: self)
    }
    
    /// Show nugu usage guide webpage after successful login process
    func showGuideWebIfNeeded() {
        guard UserDefaults.Standard.hasSeenGuideWeb == false,
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
        voiceChromeDismissWorkItem?.cancel()
        nuguVoiceChrome.removeFromSuperview()
        nuguVoiceChrome = NuguVoiceChrome(frame: CGRect(x: 0, y: self.view.frame.size.height, width: self.view.frame.size.width, height: NuguVoiceChrome.recommendedHeight + SampleApp.bottomSafeAreaHeight))
        view.addSubview(self.nuguVoiceChrome)
        showVoiceChrome()
        
        setChipsButton(
            actionList: [("오늘 날씨 알려줘", nil), ("습도 알려줘", nil)],
            normalList: [("라디오 목록 알려줘", nil), ("템플릿 열어줘", nil), ("템플릿에서 도움말1", nil), ("주말 날씨 알려줘", nil), ("오존 농도 알려줘", nil), ("멜론 틀어줘", nil), ("NUGU 토픽 알려줘", nil)]
        )
        nuguButton.isActivated = false
        
        NuguCentralManager.shared.startMicInputProvider(requestingFocus: true) { [weak self] success in
            guard let self = self else { return }
            guard success else {
                log.error("Start MicInputProvider failed")
                DispatchQueue.main.async { [weak self] in
                    self?.dismissVoiceChrome()
                }
                return
            }
            
            NuguCentralManager.shared.startRecognition(initiator: initiator)
        }
    }
    
    func showVoiceChrome() {
        let showAnimation = {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: -self.nuguVoiceChrome.bounds.height)
            }
        }
        
        if view.subviews.contains(nuguVoiceChrome) == false {
            nuguVoiceChrome = NuguVoiceChrome(frame: CGRect(x: 0, y: view.frame.size.height, width: view.frame.size.width, height: NuguVoiceChrome.recommendedHeight + SampleApp.bottomSafeAreaHeight))
            view.addSubview(nuguVoiceChrome)
            showAnimation()
        } else {
            if nuguVoiceChrome.frame.origin.y != view.frame.size.height - nuguVoiceChrome.bounds.height {
                showAnimation()
            }
        }
        addTapGestureRecognizerForDismissVoiceChrome()
    }
    
    func dismissVoiceChrome() {
        view.gestureRecognizers = nil
        
        voiceChromeDismissWorkItem?.cancel()
        
        nuguButton.isActivated = true
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self else { return }
            self.nuguVoiceChrome.transform = CGAffineTransform(translationX: 0.0, y: self.nuguVoiceChrome.bounds.height)
        }, completion: { [weak self] _ in
            self?.nuguVoiceChrome.removeFromSuperview()
        })
    }
    
    func setChipsButton(actionList: [(text: String, token: String?)], normalList: [(text: String, token: String?)]) {
        var chipsButtonList = [NuguChipsButton.NuguChipsButtonType]()
        let actionButtonList = actionList.map { NuguChipsButton.NuguChipsButtonType.action(text: $0.text, token: $0.token) }
        chipsButtonList.append(contentsOf: actionButtonList)
        let normalButtonList = normalList.map { NuguChipsButton.NuguChipsButtonType.normal(text: $0.text, token: $0.token) }
        chipsButtonList.append(contentsOf: normalButtonList)
        nuguVoiceChrome.setChipsData(
            chipsData: chipsButtonList,
            onChipsSelect: { [weak self] selectedChips in
                self?.chipsDidSelect(selectedChips: selectedChips)
            }
        )
    }
    
    func addTapGestureRecognizerForDismissVoiceChrome() {
        view.gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapForDismissVoiceChrome))
        view.addGestureRecognizer(tapGestureRecognizer)
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
    func makeDisplayView(displayTemplate: DisplayTemplate) -> DisplayView? {
        let displayView: DisplayView?

        switch displayTemplate.type {
        case "Display.FullText1":
            displayView = FullText1View(frame: view.frame)
        case "Display.FullText2":
            displayView = FullText2View(frame: view.frame)
        case "Display.FullText3":
            displayView = FullText3View(frame: view.frame)
        case "Display.ImageText1":
            displayView = ImageText1View(frame: view.frame)
        case "Display.ImageText2":
            displayView = ImageText2View(frame: view.frame)
        case "Display.ImageText3":
            displayView = ImageText3View(frame: view.frame)
        case "Display.ImageText4":
            displayView = ImageText4View(frame: view.frame)
        case "Display.FullImage":
            displayView = FullImageView(frame: view.frame)
        case "Display.Score1":
            displayView = Score1View(frame: view.frame)
        case "Display.Score2":
            displayView = Score2View(frame: view.frame)
        case "Display.TextList1":
            displayView = TextList1View(frame: view.frame)
        case "Display.TextList2":
            displayView = TextList2View(frame: view.frame)
        case "Display.TextList3":
            displayView = TextList3View(frame: view.frame)
        case "Display.TextList4":
            displayView = TextList4View(frame: view.frame)
        case "Display.ImageList1":
            displayView = ImageList1View(frame: view.frame)
        case "Display.ImageList2":
            displayView = ImageList2View(frame: view.frame)
        case "Display.ImageList3":
            displayView = ImageList3View(frame: view.frame)
        case "Display.Weather1":
            displayView = Weather1View(frame: view.frame)
        case "Display.Weather2":
            displayView = Weather2View(frame: view.frame)
        case "Display.Weather3":
            displayView = Weather3View(frame: view.frame)
        case "Display.Weather4":
            displayView = Weather4View(frame: view.frame)
        case "Display.Weather5":
            displayView = Weather5View(frame: view.frame)
        default:
            // Draw your own DisplayView with DisplayTemplate.payload and set as self.displayView
            displayView = nil
        }
        return displayView
    }
    
    func addDisplayView(displayTemplate: DisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        displayView?.removeFromSuperview()
        
        guard let displayView = makeDisplayView(displayTemplate: displayTemplate) else {
            completion(nil)
            return
        }
        
        displayView.displayPayload = displayTemplate.payload
        displayView.onCloseButtonClick = { [weak self] in
            guard let self = self else { return }
            NuguCentralManager.shared.client.ttsAgent.stopTTS()
            self.dismissDisplayView()
        }
        displayView.onItemSelect = { eventType in
            switch eventType {
            case .elementSelected(let token, let postback):
                guard let token = token else { return }
                NuguCentralManager.shared.client.displayAgent.elementDidSelect(templateId: displayTemplate.templateId, token: token, postback: postback)
            case .textInput(let token, let textInput):
                guard let textInput = textInput  else { return }
                if let playServiceId = textInput.playServiceId {
                    NuguCentralManager.shared.requestTextInput(text: textInput.text, token: token, requestType: .specific(playServiceId: playServiceId))
                } else {
                    NuguCentralManager.shared.requestTextInput(text: textInput.text, token: token, requestType: .normal)
                }
            }
        }
        
        displayView.onUserInteraction = {
            NuguCentralManager.shared.client.displayAgent.notifyUserInteraction()
        }
        displayView.onChipsSelect = { [weak self] (selectedChips) in
            self?.chipsDidSelect(selectedChips: selectedChips)
        }
        displayView.onNuguButtonClick = { [weak self] in
            self?.presentVoiceChrome(initiator: .user)
        }
        
        displayView.alpha = 0
        view.insertSubview(displayView, belowSubview: nuguVoiceChrome)
        
        UIView.animate(withDuration: 0.3, animations: {
            displayView.alpha = 1.0
        }, completion: { [weak self] (_) in
            completion(displayView)
            self?.displayView = displayView
        })
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

// MARK: - Private (DisplayAudioPlayerView)

private extension MainViewController {
    func makeDisplayAudioPlayerView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate) -> AudioDisplayView? {
        let displayAudioPlayerView: AudioDisplayView?
        
        switch audioPlayerDisplayTemplate.type {
        case "AudioPlayer.Template1":
            displayAudioPlayerView = AudioPlayer1View(frame: view.frame)
        case "AudioPlayer.Template2":
            displayAudioPlayerView = AudioPlayer2View(frame: view.frame)
        default:
            // Draw your own AudioPlayerView with AudioPlayerDisplayTemplate.payload and set as self.displayAudioPlayerView
            displayAudioPlayerView = nil
        }
        
        return displayAudioPlayerView
    }
    
    func addDisplayAudioPlayerView(audioPlayerDisplayTemplate: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        let wasPlayerBarMode = displayAudioPlayerView?.isBarMode == true
        displayAudioPlayerView?.removeFromSuperview()
        
        guard let audioPlayerView = makeDisplayAudioPlayerView(audioPlayerDisplayTemplate: audioPlayerDisplayTemplate) else {
            completion(nil)
            return
        }

        if wasPlayerBarMode == true {
            audioPlayerView.setBarMode()
        }
        
        audioPlayerView.isSeekable = audioPlayerDisplayTemplate.isSeekable
        audioPlayerView.displayPayload = audioPlayerDisplayTemplate.payload
        audioPlayerView.onCloseButtonClick = { [weak self] in
            guard let self = self else { return }
            self.dismissDisplayAudioPlayerView()
            NuguCentralManager.shared.displayPlayerController.remove()
        }
        audioPlayerView.onUserInteraction = {
            NuguCentralManager.shared.client.audioPlayerAgent.notifyUserInteraction()
        }
        audioPlayerView.onChipsSelect = { [weak self] selectedChips in
            self?.chipsDidSelect(selectedChips: selectedChips)
        }
        audioPlayerView.onNuguButtonClick = { [weak self] in
            self?.presentVoiceChrome(initiator: .user)
        }
        
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

// MARK: - DialogStateDelegate

extension MainViewController: DialogStateDelegate {
    func dialogStateDidChange(_ state: DialogState, isMultiturn: Bool, chips: [ChipsAgentItem.Chip]?, sessionActivated: Bool) {
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
                self.showVoiceChrome()
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
                self.showVoiceChrome()
                if isMultiturn || sessionActivated {
                    self.nuguVoiceChrome.changeState(state: .listeningPassive)
                    self.nuguVoiceChrome.setRecognizedText(text: nil)
                    self.nuguButton.isActivated = false
                }
                if let chips = chips {
                    let actionList = chips.filter { $0.type == .action }.map { ($0.text, $0.token) }
                    let normalList = chips.filter { $0.type == .general }.map { ($0.text, $0.token) }
                    self.setChipsButton(actionList: actionList, normalList: normalList)
                }
                NuguCentralManager.shared.asrBeepPlayer.beep(type: .start)
            }
        case .recognizing:
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.changeState(state: .listeningActive)
            }
        case .thinking:
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.changeState(state: .processing)
                self?.nuguButton.pauseDeactivateAnimation()
            }
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
        case .complete(let text):
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.setRecognizedText(text: text)
                NuguCentralManager.shared.asrBeepPlayer.beep(type: .success)
            }
        case .partial(let text):
            DispatchQueue.main.async { [weak self] in
                self?.nuguVoiceChrome.setRecognizedText(text: text)
            }
        case .error(let error):
            DispatchQueue.main.async { [weak self] in
                switch error {
                case ASRError.listenFailed:
                    NuguCentralManager.shared.asrBeepPlayer.beep(type: .fail)
                    self?.nuguVoiceChrome.changeState(state: .speakingError)
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

// MARK: - TextAgentDelegate

extension MainViewController: TextAgentDelegate {
    func textAgentShouldHandleTextSource(directive: Downstream.Directive) -> Bool {
        return true
    }
}

// MARK: - DisplayAgentDelegate

extension MainViewController: DisplayAgentDelegate {
    func displayAgentRequestContext(templateId: String, completion: @escaping (DisplayContext?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                let displayControllableView = self.displayView as? DisplayControllable else {
                    return completion(nil)
            }

            let focusedItemToken: String? = {
                guard self.displayView?.supportVisibleTokenList == true else { return nil }
                return displayControllableView.focusedItemToken()
            }()
            let visibleTokenList = { () -> [String]? in
                guard self.displayView?.supportVisibleTokenList == true else { return nil }
                return displayControllableView.visibleTokenList()
            }()
            
            completion(DisplayContext(focusedItemToken: focusedItemToken, visibleTokenList: visibleTokenList))
        }
    }
    
    func displayAgentShouldMoveFocus(templateId: String, direction: DisplayControlPayload.Direction, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let displayControllableView = self?.displayView as? DisplayControllable else {
                completion(false)
                return
            }
            
            completion(displayControllableView.focus(direction: direction))
        }
    }
    
    func displayAgentShouldScroll(templateId: String, direction: DisplayControlPayload.Direction, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let displayControllableView = self?.displayView as? DisplayControllable else {
                completion(false)
                return
            }
            completion(displayControllableView.scroll(direction: direction))
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
    func audioPlayerDisplayShouldShowLyrics(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.displayAudioPlayerView?.shouldShowLyrics() ?? false)
        }
    }
    
    func audioPlayerDisplayShouldHideLyrics(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.displayAudioPlayerView?.shouldHideLyrics() ?? false)
        }
    }
    
    func audioPlayerIsLyricsVisible(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            completion(self?.displayAudioPlayerView?.isLyricsVisible ?? false)
        }
    }
    
    func audioPlayerDisplayShouldControlLyricsPage(direction: AudioPlayerDisplayControlPayload.Direction, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            completion(false)
        }
    }
    
    func audioPlayerDisplayShouldRender(template: AudioPlayerDisplayTemplate, completion: @escaping (AnyObject?) -> Void) {
        log.debug("")
        DispatchQueue.main.async { [weak self] in
            NuguCentralManager.shared.displayPlayerController.nuguAudioPlayerDisplayDidRender(template: template)
            self?.addDisplayAudioPlayerView(audioPlayerDisplayTemplate: template, completion: completion)
        }
    }
    
    func audioPlayerDisplayDidClear(template: AudioPlayerDisplayTemplate) {
        log.debug("")
        DispatchQueue.main.async { [weak self] in
            NuguCentralManager.shared.displayPlayerController.nuguAudioPlayerDisplayDidClear()
            self?.dismissDisplayAudioPlayerView()
        }
    }
    
    func audioPlayerDisplayShouldUpdateMetadata(payload: Data) {
        DispatchQueue.main.async { [weak self] in
            self?.displayAudioPlayerView?.updateSettings(payload: payload)
        }
    }
}

// MARK: - AudioPlayerAgentDelegate

extension MainViewController: AudioPlayerAgentDelegate {
    func audioPlayerAgentDidChange(state: AudioPlayerState, header: Downstream.Header) {
        log.debug("audioPlayerAgentDidChange : \(state)")
        NuguCentralManager.shared.displayPlayerController.nuguAudioPlayerAgentDidChange(state: state)
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
}
