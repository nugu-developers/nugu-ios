//
//  ASRAgent.swift
//  NuguAgents
//
//  Created by MinChul Lee on 17/04/2019.
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

import Foundation

import NuguCore
import JadeMarble

import RxSwift

public final class ASRAgent: ASRAgentProtocol {
    // CapabilityAgentable
    // TODO: ASR interface version 1.1 -> ASR.Recognize(wakeup, timeout)
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .automaticSpeechRecognition, version: "1.1")
    
    // Private
    private let focusManager: FocusManageable
    private let contextManager: ContextManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let audioStream: AudioStreamable
    fileprivate static var endPointDetector: EndPointDetector?
    
    private let asrDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.asr_agent", qos: .userInitiated)
    
    private let asrDelegates = DelegateSet<ASRAgentDelegate>()
    
    private var asrState: ASRState = .idle {
        didSet {
            log.info("From:\(oldValue) To:\(asrState)")
            
            // `expectingSpeechTimeout` -> `ASRRequest` -> `FocusState` -> EndPointDetector` -> `ASRAgentDelegate`
            // dispose expectingSpeechTimeout
            if asrState != .expectingSpeech {
                expectingSpeechTimeout?.dispose()
            }
            
            // release asrRequest
            if asrState == .idle {
                asrRequest = nil
                releaseFocusIfNeeded()
            }

            // Stop EPD
            if [.listening, .recognizing].contains(asrState) == false &&
                [.start, .listening].contains(Self.endPointDetector?.state) {
                Self.endPointDetector?.stop()
            }
            
            // Notify delegates only if the agent's status changes.
            if oldValue != asrState {
                asrDelegates.notify { delegate in
                    delegate.asrAgentDidChange(state: asrState, expectSpeech: expectSpeech)
                }
            }
        }
    }
    
    private var asrResult: ASRResult = .none {
        didSet {
            log.info("\(asrResult)")
            guard let asrRequest = asrRequest else {
                asrState = .idle
                log.error("ASRRequest not exist")
                return
            }
            
            // ASRExpectSpeech -> `ASRState` -> Event -> `ASRAgentDelegate`
            switch asrResult {
            case .none:
                // Focus 는 결과 directive 받은 후 release 해주어야 함.
                expectSpeech = nil
            case .partial:
                break
            case .complete:
                // Focus 는 결과 directive 받은 후 release 해주어야 함.
                expectSpeech = nil
            case .cancel:
                expectSpeech = nil
                asrState = .idle
                upstreamDataSender.cancelEvent(dialogRequestId: asrRequest.dialogRequestId)
                upstreamDataSender.sendEvent(
                    Event(typeInfo: .stopRecognize, expectSpeech: expectSpeech)
                        .makeEventMessage(agent: self, referrerDialogRequestId: asrRequest.dialogRequestId)
                )
            case .error(let error):
                expectSpeech = nil
                asrState = .idle
                switch error {
                case NetworkError.timeout:
                    upstreamDataSender.sendEvent(
                        Event(typeInfo: .responseTimeout, expectSpeech: expectSpeech)
                            .makeEventMessage(agent: self, referrerDialogRequestId: asrRequest.dialogRequestId)
                    )
                case ASRError.listeningTimeout:
                    upstreamDataSender.sendEvent(
                        Event(typeInfo: .listenTimeout, expectSpeech: expectSpeech)
                            .makeEventMessage(agent: self, referrerDialogRequestId: asrRequest.dialogRequestId)
                    )
                case ASRError.listenFailed:
                    upstreamDataSender.sendEvent(
                        Event(typeInfo: .listenFailed, expectSpeech: expectSpeech)
                            .makeEventMessage(agent: self, referrerDialogRequestId: asrRequest.dialogRequestId)
                    )
                case ASRError.recognizeFailed:
                    break
                default:
                    break
                }
            }
            
            asrRequest.completion?(asrResult, asrRequest.dialogRequestId)
        }
    }
    
    // For Recognize Event
    private var asrRequest: ASRRequest?
    private var attachmentSeq: Int32 = 0
    public private(set) var expectSpeech: ASRExpectSpeech? {
        didSet {
            guard oldValue != expectSpeech else { return }
            
            asrDelegates.notify { delegate in
                delegate.asrAgentDidChange(state: asrState, expectSpeech: expectSpeech)
            }
        }
    }
    
    private lazy var disposeBag = DisposeBag()
    private var expectingSpeechTimeout: Disposable?
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "ExpectSpeech", blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true), preFetch: prefetchExpectSpeech, directiveHandler: handleExpectSpeech),
        DirectiveHandleInfo(namespace: capabilityAgentProperty.name, name: "NotifyResult", blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false), directiveHandler: handleNotifyResult)
    ]
    
    public init(
        focusManager: FocusManageable,
        upstreamDataSender: UpstreamDataSendable,
        contextManager: ContextManageable,
        audioStream: AudioStreamable,
        directiveSequencer: DirectiveSequenceable
    ) {
        Self.endPointDetector = EndPointDetector()
        
        self.focusManager = focusManager
        self.upstreamDataSender = upstreamDataSender
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.audioStream = audioStream
        
        Self.endPointDetector?.delegate = self
        contextManager.add(provideContextDelegate: self)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        Self.endPointDetector = nil
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
}

// MARK: - ASRAgentProtocol

public extension ASRAgent {
    func add(delegate: ASRAgentDelegate) {
        asrDelegates.add(delegate)
    }
    
    func remove(delegate: ASRAgentDelegate) {
        asrDelegates.remove(delegate)
    }
    
    @discardableResult func startRecognition(
        options: ASROptions,
        completion: ((_ asrResult: ASRResult, _ dialogRequestId: String) -> Void)?
    ) -> String {
        return startRecognition(options: options, by: nil, completion: completion)
    }
    
    /// This function asks the ASRAgent to stop streaming audio and end an ongoing Recognize Event, which transitions it to the BUSY state.
    ///
    /// This function can only be called in the LISTENING and RECOGNIZING state.
    private func stopSpeech() {
        log.debug("")
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            switch self.asrState {
            case .listening, .recognizing:
                self.executeStopSpeech()
            case .idle, .expectingSpeech, .busy:
                log.warning("Not permitted in current state \(self.asrState)")
                return
            }
        }
    }
    
    func stopRecognition() {
        log.debug("")
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            // TODO: cancelAssociation = true 로 tts 가 종료되어도 expectSpeech directive 가 전달되는 현상으로 우선 currentExpectSpeech nil 처리.
            self.expectSpeech = nil
            guard self.asrState != .idle else {
                log.info("Not permitted in current state, \(self.asrState)")
                return
            }

            self.asrResult = .cancel
        }
    }
}

// MARK: - FocusChannelDelegate

extension ASRAgent: FocusChannelDelegate {
    public func focusChannelPriority() -> FocusChannelPriority {
        return .recognition
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("Focus:\(focusState) ASR:\(asrState)")
        
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch (focusState, self.asrState) {
            case (.foreground, let asrState) where [.idle, .expectingSpeech].contains(asrState):
                self.executeStartCapture()
            // Listening, Recognizing, Busy 무시
            case (.foreground, _):
                break
            // Background 허용 안함.
            case _ where self.asrRequest != nil:
                self.asrResult = .cancel
            default:
                break
            }
        }
    }
}

// MARK: - ContextInfoDelegate

extension ASRAgent: ContextInfoDelegate {
    public func contextInfoRequestContext(completion: (ContextInfo?) -> Void) {
        let payload: [String: AnyHashable] = [
            "version": capabilityAgentProperty.version,
            "engine": "skt"
        ]
        completion(ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - EndPointDetectorDelegate

extension ASRAgent: EndPointDetectorDelegate {
    public func endPointDetectorDidError() {
        asrDispatchQueue.async { [weak self] in
            self?.asrResult = .error(ASRError.listenFailed)
        }
    }
    
    public func endPointDetectorStateChanged(_ state: EndPointDetectorState) {
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            switch self.asrState {
            case .listening, .recognizing:
                break
            case .idle, .expectingSpeech, .busy:
                log.warning("Not permitted in current state \(self.asrState)")
                return
            }
            
            switch state {
            case .idle:
                break
            case .listening:
                break
            case .start:
                self.asrState = .recognizing
            case .end, .reachToMaxLength, .finish, .unknown:
                self.executeStopSpeech()
            case .timeout:
                self.asrResult = .error(ASRError.listeningTimeout)
            }
        }
    }
    
    public func endPointDetectorSpeechDataExtracted(speechData: Data) {
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let asrRequest = self.asrRequest  else {
                log.warning("ASRRequest not exist")
                return
            }
            switch self.asrState {
            case .listening, .recognizing:
                break
            case .idle, .expectingSpeech, .busy:
                log.warning("Not permitted in current state \(self.asrState)")
                return
            }
            
            let attachmentHeader = Upstream.Attachment.Header(
                namespace: self.capabilityAgentProperty.name,
                name: "Recognize",
                version: self.capabilityAgentProperty.version,
                dialogRequestId: asrRequest.dialogRequestId,
                messageId: TimeUUID().hexString
            )
            let attachment = Upstream.Attachment(header: attachmentHeader, content: speechData, type: "audio/speex", seq: self.attachmentSeq, isEnd: false)
            self.upstreamDataSender.sendStream(attachment)
            self.attachmentSeq += 1
            log.debug("request seq: \(self.attachmentSeq-1)")
        }
    }
}

// MARK: - Private (Directive)

private extension ASRAgent {
    func prefetchExpectSpeech() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
                Result { [weak self] in
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                    }
                    
                    self?.expectSpeech = try JSONDecoder().decode(ASRExpectSpeech.self, from: data)
                }
            )
        }
        
    }

    func handleExpectSpeech() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
                Result { [weak self] in
                    guard let self = self else { return }
                    guard let expectSpeech = self.expectSpeech else {
                        throw HandleDirectiveError.handleDirectiveError(message: "currentExpectSpeech is nil")
                    }
                    switch self.asrState {
                    case .idle, .busy:
                        break
                    case .expectingSpeech, .listening, .recognizing:
                        throw HandleDirectiveError.handleDirectiveError(message: "ExpectSpeech only allowed in IDLE or BUSY state.")
                    }
                    
                    self.asrDispatchQueue.async { [weak self] in
                        guard let self = self else { return }
                        
                        self.asrState = .expectingSpeech
                        self.expectingSpeechTimeout = Observable<Int>
                            .timer(ASRConst.focusTimeout, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                            .subscribe(onNext: { [weak self] _ in
                                log.info("expectingSpeechTimeout")
                                self?.asrResult = .error(ASRError.listenFailed)
                            })
                        self.expectingSpeechTimeout?.disposed(by: self.disposeBag)
                        
                        let options = ASROptions(timeout: expectSpeech.timeout, initiator: .scenario)
                        self.startRecognition(options: options, by: directive)
                    }
                }
            )
        }
    }
    
    func handleNotifyResult() -> HandleDirective {
        return { [weak self] directive, completion in
            completion(
                Result { [weak self] in
                    guard let data = directive.payload.data(using: .utf8) else {
                        throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                    }
                    
                    let item = try JSONDecoder().decode(ASRNotifyResult.self, from: data)
                    
                    self?.asrDispatchQueue.async { [weak self] in
                        guard let self = self else { return }
                        
                        switch item.state {
                        case .partial:
                            self.asrResult = .partial(text: item.result ?? "")
                        case .complete:
                            self.asrResult = .complete(text: item.result ?? "")
                        case .none:
                            self.asrResult = .none
                        case .error:
                            self.asrResult = .error(ASRError.recognizeFailed)
                        case .sos, .eos, .reset, .falseAcceptance:
                            // TODO 추후 Server EPD 개발시 구현
                            break
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Private(FocusManager)

private extension ASRAgent {
    func releaseFocusIfNeeded() {
        guard asrState == .idle else {
            log.info("Not permitted in current state, \(asrState)")
            return
        }
        
        focusManager.releaseFocus(channelDelegate: self)
    }
}

// MARK: - Private(EndPointDetector)

private extension ASRAgent {
    /// asrDispatchQueue
    func executeStartCapture() {
        guard let asrRequest = asrRequest else {
            log.error("ASRRequest not exist")
            asrResult = .cancel
            return
        }
        
        attachmentSeq = 0
        
        var timeout: Int {
            guard let expectTimeout = expectSpeech?.timeoutInMilliseconds else {
                return asrRequest.options.timeout
            }
            
            return expectTimeout / 1000
        }
        
        Self.endPointDetector?.start(
            audioStreamReader: asrRequest.reader,
            sampleRate: asrRequest.options.sampleRate,
            timeout: timeout,
            maxDuration: asrRequest.options.maxDuration,
            pauseLength: asrRequest.options.pauseLength
        )
        
        asrState = .listening
        
        upstreamDataSender.sendStream(
            Event(
                typeInfo: .recognize(wakeUpInfo: nil, options: asrRequest.options),
                expectSpeech: expectSpeech
            ).makeEventMessage(
                agent: self,
                dialogRequestId: asrRequest.dialogRequestId,
                contextPayload: asrRequest.contextPayload
            )) { [weak self] (state) in
                self?.asrDispatchQueue.async { [weak self] in
                    guard self?.asrRequest?.dialogRequestId == asrRequest.dialogRequestId else { return }
                    
                    switch state {
                    case .finished:
                        self?.asrState = .idle
                    case .error(let error):
                        self?.asrResult = .error(error)
                    default:
                        break
                    }
                }
        }
    }
    
    /// asrDispatchQueue
    func executeStopSpeech() {
        guard let asrRequest = asrRequest else {
            log.error("ASRRequest not exist")
            asrResult = .cancel
            return
        }
        switch asrState {
        case .recognizing, .listening:
            break
        case .idle, .expectingSpeech, .busy:
            log.warning("Not permitted in current state \(self.asrState)")
            return
        }
        
        asrState = .busy
        
        let attachmentHeader = Upstream.Attachment.Header(
            namespace: capabilityAgentProperty.name,
            name: "Recognize",
            version: capabilityAgentProperty.version,
            dialogRequestId: asrRequest.dialogRequestId,
            messageId: TimeUUID().hexString
        )
        let attachment = Upstream.Attachment(header: attachmentHeader, content: Data(), type: "audio/speex", seq: attachmentSeq, isEnd: true)
        upstreamDataSender.sendStream(attachment)
    }
    
    @discardableResult func startRecognition(
        options: ASROptions = ASROptions(),
        by directive: Downstream.Directive?,
        completion: ((_ asrResult: ASRResult, _ dialogRequestId: String) -> Void)? = nil
    ) -> String {
        log.debug("startRecognition, initiator: \(options.initiator)")
        // reader 는 최대한 빨리 만들어줘야 Data 유실이 없음.
        let reader = audioStream.makeAudioStreamReader()
        let dialogRequestId = TimeUUID().hexString
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }

            guard [.listening, .recognizing, .busy].contains(self.asrState) == false else {
                log.warning("Not permitted in current state \(self.asrState)")
                completion?(.cancel, dialogRequestId)
                return
            }

            self.contextManager.getContexts { [weak self] contextPayload in
                guard let self = self else { return }

                self.asrRequest = ASRRequest(
                    contextPayload: contextPayload,
                    reader: reader,
                    dialogRequestId: dialogRequestId,
                    options: options,
                    referrerDialogRequestId: directive?.header.dialogRequestId,
                    completion: completion
                )

                self.focusManager.requestFocus(channelDelegate: self)
            }
        }
        
        return dialogRequestId
    }
}

// MARK: - ASRAgentProtocol

extension ASRAgentProtocol {
    /// File that you have for end point detection
    public var epdFile: URL? {
        get {
            return ASRAgent.endPointDetector?.epdFile
        }
        
        set {
            ASRAgent.endPointDetector?.epdFile = newValue
        }
    }
}
