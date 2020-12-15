//
//  NuguCentralManager.swift
//  SampleApp
//
//  Created by yonghoonKwon on 25/07/2019.
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

import NuguCore
import NuguAgents
import NuguClientKit
import NuguLoginKit
import NuguUIKit

final class NuguCentralManager {
    static let shared = NuguCentralManager()
    
    private var authorizationInfo: AuthorizationInfo? {
        didSet {
            guard let authorizationInfo = authorizationInfo else { return }
            
            UserDefaults.Standard.accessToken = authorizationInfo.accessToken
            UserDefaults.Standard.refreshToken = authorizationInfo.refreshToken
        }
    }
    
    lazy private(set) var client: NuguClient = {
        let client = NuguClient(delegate: self)
        
        client.locationAgent.delegate = self
        client.systemAgent.add(systemAgentDelegate: self)
        client.soundAgent.dataSource = self
        client.ttsAgent.directiveCancelPolicy = DirectiveCancelPolicy(cancelAll: false, cancelTargets: ["MediaPlayer.Play"])
        
        if let epdFile = Bundle.main.url(forResource: "skt_epd_model", withExtension: "raw") {
            client.asrAgent.options = ASROptions(endPointing: .client(epdFile: epdFile))
        } else {
            log.error("EPD model file not exist")
        }
        
        return client
    }()
    
    lazy private(set) var localTTSAgent: LocalTTSAgent = LocalTTSAgent(focusManager: client.focusManager)
    lazy private(set) var asrBeepPlayer: ASRBeepPlayer = ASRBeepPlayer(focusManager: client.focusManager)

    let displayPlayerController = NuguDisplayPlayerController()
    
    lazy private(set) var oauthClient: NuguOAuthClient = {
        do {
            return try NuguOAuthClient(serviceName: Bundle.main.bundleIdentifier ?? "NuguSample")
        } catch {
            log.warning("OAuthClient has instantiated by using deviceUniqueId")
            return NuguOAuthClient(deviceUniqueId: "sample-device-unique-id")
        }
    }()
    
    private var startMicWorkItem: DispatchWorkItem?

    // Audio input source
    private let micQueue = DispatchQueue(label: "central_manager_mic_input_queue")
    private let micInputProvider = MicInputProvider()
    
    private init() {
        // TODO: - should be removed after configuration metadata has been applied
        if let deviceTypeCode = ConfigurationStore.shared.configuration?.deviceTypeCode {
            NuguDisplayWebView.deviceTypeCode = deviceTypeCode
        }
    }
}

// MARK: - Internal (Enable / Disable)

extension NuguCentralManager {
    func enable() {
        log.debug("")
        if authorizationInfo?.availableServerInitiatedDirective == true {
            client.startReceiveServerInitiatedDirective()
        } else {
            client.stopReceiveServerInitiatedDirective()
        }

        NuguLocationManager.shared.startUpdatingLocation()
        
        // Set Last WakeUp Keyword
        // If you don't want to use saved wakeup-word, don't need to be implemented
        if UserDefaults.Standard.useWakeUpDetector,
            let keyword = Keyword(rawValue: UserDefaults.Standard.wakeUpWord) {
            client.keywordDetector.keywordSource = keyword.keywordSource
            startWakeUpDetector()
            
            startMicWorkItem?.cancel()
            startMicWorkItem = DispatchWorkItem(block: { [weak self] in
                log.debug("startMicWorkItem start")
                self?.startMicInputProvider(requestingFocus: false) { (success) in
                    guard success else {
                        log.debug("startMicWorkItem failed!")
                        return
                    }
                }
            })
            guard let startMicWorkItem = startMicWorkItem else { return }
            // When mic has been activated before interruption end notification has been fired,
            // Option's .shouldResume factor never comes in. (even when it has to be)
            // Giving small delay for starting mic can be a solution for this situation
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: startMicWorkItem)
        } else {
            stopWakeUpDetector()
            stopMicInputProvider()
        }
    }
    
    func disable() {
        log.debug("")
        stopWakeUpDetector()
        stopMicInputProvider()
        stopRecognition()
        client.stopReceiveServerInitiatedDirective()
        client.ttsAgent.stopTTS()
        client.audioPlayerAgent.stop()
    }
}

// MARK: - Internal (OAuth)

extension NuguCentralManager {
    func login(from viewController: UIViewController, completion: @escaping (Result<Void, SampleAppError>) -> Void) {
        guard let loginMethod = SampleApp.loginMethod else {
            completion(.failure(SampleAppError.nilValue(description: "loginMethod is nil")))
            return
        }
        
        switch loginMethod {
        case .type1:
            oauthClient.authorizeWithTid(parentViewController: viewController) { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    self?.authorizationInfo = authInfo
                    completion(.success(()))
                case .failure(let error):
                    let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: error)
                    completion(.failure(sampleAppError))
                }
            }
        case .type2:
            oauthClient.authorize { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    self?.authorizationInfo = authInfo
                    completion(.success(()))
                case .failure(let error):
                    let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: error)
                    completion(.failure(sampleAppError))
                }
            }
        }
    }
    
    func refreshToken(completion: @escaping (Result<Void, SampleAppError>) -> Void) {
        guard let loginMethod = SampleApp.loginMethod else {
            log.info("loginMethod is nil")
            completion(.failure(SampleAppError.nilValue(description: "loginMethod is nil")))
            return
        }
        guard let refreshToken = UserDefaults.Standard.refreshToken else {
            completion(.failure(SampleAppError.nilValue(description: "RefreshToken is nil")))
            return
        }
        
        switch loginMethod {
        case .type1:
            oauthClient.refreshToken(refreshToken: refreshToken) { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    self?.authorizationInfo = authInfo
                    completion(.success(()))
                case .failure(let error):
                    let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: error)
                    completion(.failure(sampleAppError))
                }
            }
        case .type2:
            oauthClient.authorize { [weak self] (result) in
                switch result {
                case .success(let authInfo):
                    self?.authorizationInfo = authInfo
                    completion(.success(()))
                case .failure(let error):
                    let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: error)
                    completion(.failure(sampleAppError))
                }
            }
        }
    }
    
    func revoke() {
        oauthClient.revoke { [weak self] (result) in
            switch result {
            case .success:
                self?.clearSampleApp()
            case .failure(let nuguLoginKitError):
                log.debug(nuguLoginKitError.localizedDescription)
            }
        }
    }
    
    func clearSampleApp() {
        authorizationInfo = nil
        popToRootViewController()
        disable()
        UserDefaults.Standard.clear()
        UserDefaults.Nugu.clear()
    }
    
    func getUserInfo(completion: @escaping (Result<NuguUserInfo, NuguLoginKitError>) -> Void) {
        oauthClient.getUserInfo(completion: completion)
    }
    
    func showTidInfo(parentViewController: UIViewController, completion: @escaping () -> Void) {
        guard SampleApp.loginMethod == SampleApp.LoginMethod.type1 else {
            log.error("loginMethod is not type1")
            completion()
            return
        }
        
        oauthClient.showTidInfo(parentViewController: parentViewController) { [weak self] (result) in
            if case .success(let authInfo) = result {
                self?.authorizationInfo = authInfo
            }
            completion()
        }
    }
}

// MARK: - Private (Clear Sample App)

private extension NuguCentralManager {
    func popToRootViewController() {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let rootNavigationViewController = appDelegate.window?.rootViewController as? UINavigationController else { return }
            rootNavigationViewController.popToRootViewController(animated: true)
        }
    }
    
    func clearSampleAppAfterErrorHandling(sampleAppError: SampleAppError) {
        DispatchQueue.main.async { [weak self] in
            self?.client.audioPlayerAgent.stop()
            NuguToast.shared.showToast(message: sampleAppError.errorDescription)
            self?.popToRootViewController()
            switch sampleAppError {
            case .loginUnauthorized:
                self?.localTTSAgent.playLocalTTS(type: .pocStateServiceTerminated, completion: { [weak self] in
                    self?.authorizationInfo = nil
                    self?.disable()
                    UserDefaults.Standard.clear()
                    UserDefaults.Nugu.clear()
                })
            default:
                self?.localTTSAgent.playLocalTTS(type: .deviceGatewayAuthError, completion: { [weak self] in
                    self?.authorizationInfo = nil
                    self?.disable()
                    UserDefaults.Standard.clear()
                    UserDefaults.Nugu.clear()
                })
            }
        }
    }
}

// MARK: - Private (NetworkError handling)
// TODO: - Should consider and decide for best way for handling network errors

private extension NuguCentralManager {
    func handleNetworkError(error: Error) {
        // Handle Nugu's predefined NetworkError
        if let networkError = error as? NetworkError {
            switch networkError {
            case .authError:
                refreshToken { [weak self] result in
                    switch result {
                    case .success:
                        self?.enable()
                    case .failure(let sampleAppError):
                        self?.clearSampleAppAfterErrorHandling(sampleAppError: sampleAppError)
                    }
                }
            case .timeout:
                localTTSAgent.playLocalTTS(type: .deviceGatewayTimeout)
            default:
                localTTSAgent.playLocalTTS(type: .deviceGatewayAuthServerError)
            }
        } else { // Handle URLError
            guard let urlError = error as? URLError else { return }
            switch urlError.code {
            case .networkConnectionLost, .notConnectedToInternet: // In unreachable network status, play prepared local tts (deviceGatewayNetworkError)
                localTTSAgent.playLocalTTS(type: .deviceGatewayNetworkError)
            default: // Handle other URLErrors with your own way
                break
            }
        }
    }
}

// MARK: - Internal (MicInputProvider)

extension NuguCentralManager {
    func startMicInputProvider(requestingFocus: Bool, completion: @escaping (Bool) -> Void) {
        startMicWorkItem?.cancel()
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState == .active else {
                completion(false)
                return
            }
            
            NuguAudioSessionManager.shared.requestRecordPermission { [unowned self] isGranted in
                guard isGranted else {
                    log.error("Record permission denied")
                    completion(false)
                    return
                }
                self.micQueue.async { [unowned self] in
                    defer {
                        log.debug("addEngineConfigurationChangeNotification")
                        NuguAudioSessionManager.shared.registerAudioEngineConfigurationObserver()
                    }
                    self.micInputProvider.stop()
                    
                    // Control center does not work properly when mixWithOthers option has been included.
                    // To avoid adding mixWithOthers option when audio player is in paused state,
                    // update audioSession should be done only when requesting focus
                    if requestingFocus {
                        NuguAudioSessionManager.shared.updateAudioSession(requestingFocus: requestingFocus)
                    }
                    do {
                        try self.micInputProvider.start { [weak self] (buffer, _) in
                            if self?.client.keywordDetector.state == .active {
                                self?.client.keywordDetector.putAudioBuffer(buffer: buffer)
                            }
                            
                            if [.listening, .recognizing].contains(self?.client.asrAgent.asrState) {
                                self?.client.asrAgent.putAudioBuffer(buffer: buffer)
                            }
                        }
                        completion(true)
                    } catch {
                        log.error(error)
                        completion(false)
                    }
                }
            }
        }
    }
    
    func stopMicInputProvider() {
        micQueue.sync {
            startMicWorkItem?.cancel()
            micInputProvider.stop()
            NuguAudioSessionManager.shared.removeAudioEngineConfigurationObserver()
        }
    }
}
 
// MARK: - Internal (WakeUpDetector)

extension NuguCentralManager {
    func startWakeUpDetector() {
        client.keywordDetector.start()
    }
    
    func stopWakeUpDetector() {
        client.keywordDetector.stop()
    }
}

// MARK: - Internal (ASR)

extension NuguCentralManager {
    func startRecognition(initiator: ASRInitiator) {
        client.asrAgent.startRecognition(initiator: initiator)
    }
    
    func stopRecognition() {
        client.asrAgent.stopRecognition()
    }
}

// MARK: - Internal (Text)

extension NuguCentralManager {
    func requestTextInput(text: String, token: String? = nil, requestType: TextAgentRequestType, completion: (() -> Void)? = nil) {
        client.dialogStateAggregator.isChipsRequestInProgress = true

        client.textAgent.requestTextInput(
            text: text,
            token: token,
            requestType: requestType
        ) { [weak self] state in
            switch state {
            case .sent:
                self?.client.asrAgent.stopRecognition()
            case .finished, .error:
                NuguCentralManager.shared.client.dialogStateAggregator.isChipsRequestInProgress = false
                completion?()
            default: break
            }
        }
    }
}

// MARK: - NuguClientDelegate

extension NuguCentralManager: NuguClientDelegate {
    func nuguClientRequestAccessToken() -> String? {
        return UserDefaults.Standard.accessToken
    }
    
    func nuguClientWillRequireAudioSession() -> Bool {
        return NuguAudioSessionManager.shared.updateAudioSession(requestingFocus: true)
    }
    
    func nuguClientDidReleaseAudioSession() {
        NuguAudioSessionManager.shared.notifyAudioSessionDeactivation()
    }
    
    func nuguClientDidReceive(direcive: Downstream.Directive) {
        // Use some analytics SDK(or API) here.
        log.debug("\(direcive.header.type)")
    }
    
    func nuguClientDidReceive(attachment: Downstream.Attachment) {
        // Use some analytics SDK(or API) here.
        log.debug("\(attachment.header.type)")
    }
    
    func nuguClientWillSend(event: Upstream.Event) {
        // Use some analytics SDK(or API) here.
        log.debug("\(event.header.type)")
    }
    
    func nuguClientDidSend(event: Upstream.Event, error: Error?) {
        // Use some analytics SDK(or API) here.
        // Error: URLError or NetworkError or EventSenderError
        log.debug("\(error?.localizedDescription ?? ""): \(event.header.type)")
        guard let error = error else { return }
        handleNetworkError(error: error)
    }
    
    func nuguClientDidSend(attachment: Upstream.Attachment, error: Error?) {
        // Use some analytics SDK(or API) here.
        // Error: EventSenderError
        log.debug("\(error?.localizedDescription ?? ""): \(attachment.seq)")
    }
}

// MARK: - LocationAgentDelegate

extension NuguCentralManager: LocationAgentDelegate {
    func locationAgentRequestLocationInfo() -> LocationInfo? {
        return NuguLocationManager.shared.cachedLocationInfo
    }
}

// MARK: - SystemAgentDelegate

extension NuguCentralManager: SystemAgentDelegate {
    func systemAgentDidReceiveExceptionFail(code: SystemAgentExceptionCode.Fail, header: Downstream.Header) {
        switch code {
        case .playRouterProcessingException:
            localTTSAgent.playLocalTTS(type: .deviceGatewayPlayRouterConnectionError)
        case .ttsSpeakingException:
            localTTSAgent.playLocalTTS(type: .deviceGatewayTTSConnectionError)
        case .unauthorizedRequestException:
            refreshToken { [weak self] result in
                switch result {
                case .success:
                    self?.enable()
                case .failure(let sampleAppError):
                    self?.clearSampleAppAfterErrorHandling(sampleAppError: sampleAppError)
                }
            }
        case .internalServiceException:
            DispatchQueue.main.async {
                NuguToast.shared.showToast(message: SampleAppError.internalServiceException.errorDescription)
            }
        }
    }
    
    func systemAgentDidReceiveRevokeDevice(reason: SystemAgentRevokeReason, header: Downstream.Header) {
        clearSampleAppAfterErrorHandling(sampleAppError: .deviceRevoked(reason: reason))
    }
}

// MARK: - SoundAgentDataSource

extension NuguCentralManager: SoundAgentDataSource {
    func soundAgentRequestUrl(beepName: SoundBeepName, header: Downstream.Header) -> URL? {
        switch beepName {
        case .responseFail: return Bundle.main.url(forResource: "responsefail", withExtension: "wav")
        }
    }
}
