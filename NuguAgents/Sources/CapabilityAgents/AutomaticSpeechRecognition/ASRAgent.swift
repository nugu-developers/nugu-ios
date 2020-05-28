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
    // TODO: ASR interface version 1.1 -> ASR.Recognize(wakeup/power)
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .automaticSpeechRecognition, version: "1.2")
    
    // Private
    private let focusManager: FocusManageable
    private let contextManager: ContextManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let audioStream: AudioStreamable
    private let dialogManager: DialogManageable
    private let sessionManager: SessionManageable
    
    private var options: ASROptions = ASROptions(endPointing: .server)
    private var endPointDetector: EndPointDetectable?
    
    private let asrDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.asr_agent", qos: .userInitiated)
    
    private let asrDelegates = DelegateSet<ASRAgentDelegate>()
    
    private var asrState: ASRState = .idle {
        didSet {
            log.info("From:\(oldValue) To:\(asrState)")
            
            guard let asrRequest = asrRequest else {
                log.error("ASRRequest is nil")
                return
            }
            
            // `expectingSpeechTimeout` -> `ASRRequest` -> `FocusState` -> EndPointDetector` -> `ASRAgentDelegate`
            // dispose expectingSpeechTimeout
            if asrState != .expectingSpeech {
                expectingSpeechTimeout?.dispose()
            }
            
            // release asrRequest
            if asrState == .idle {
                self.asrRequest = nil
                releaseFocusIfNeeded()
            }
            
            // Session
            if let dialogRequestId = asrRequest.referrerDialogRequestId {
                switch asrState {
                case .listening:
                    sessionManager.sync(dialogRequestId: dialogRequestId)
                case .idle:
                    sessionManager.release(dialogRequestId: dialogRequestId)
                    dialogManager.removeAttributes()
                default:
                    break
                }
            }
            
            // Stop EPD
            if [.listening, .recognizing].contains(asrState) == false {
                endPointDetector?.stop()
                endPointDetector?.delegate = nil
                endPointDetector = nil
            }
            
            // Notify delegates only if the agent's status changes.
            if oldValue != asrState {
                asrDelegates.notify { delegate in
                    delegate.asrAgentDidChange(state: asrState, dialogRequestId: asrRequest.dialogRequestId)
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
                break
            case .partial:
                break
            case .complete:
                // Focus 는 결과 directive 받은 후 release 해주어야 함.
                break
            case .cancel:
                asrState = .idle
                upstreamDataSender.cancelEvent(dialogRequestId: asrRequest.dialogRequestId)
                sendEvent(
                    typeInfo: .stopRecognize,
                    referrerDialogRequestId: asrRequest.dialogRequestId
                )
            case .error(let error):
                asrState = .idle
                switch error {
                case NetworkError.timeout:
                    sendEvent(
                        typeInfo: .responseTimeout,
                        referrerDialogRequestId: asrRequest.dialogRequestId
                    )
                case ASRError.listeningTimeout:
                    upstreamDataSender.cancelEvent(dialogRequestId: asrRequest.dialogRequestId)
                    sendEvent(
                        typeInfo: .listenTimeout,
                        referrerDialogRequestId: asrRequest.dialogRequestId
                    )
                case ASRError.listenFailed:
                    upstreamDataSender.cancelEvent(dialogRequestId: asrRequest.dialogRequestId)
                    sendEvent(
                        typeInfo: .listenFailed,
                        referrerDialogRequestId: asrRequest.dialogRequestId
                    )
                case ASRError.recognizeFailed:
                    break
                default:
                    break
                }
            }
            
            asrDelegates.notify { (delegate) in
                delegate.asrAgentDidReceive(result: asrResult, dialogRequestId: asrRequest.dialogRequestId)
            }
        }
    }
    
    // For Recognize Event
    private var asrRequest: ASRRequest?
    private var attachmentSeq: Int32 = 0
    
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
        directiveSequencer: DirectiveSequenceable,
        dialogManager: DialogManageable,
        sessionManager: SessionManageable
    ) {
        self.focusManager = focusManager
        self.upstreamDataSender = upstreamDataSender
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.audioStream = audioStream
        self.dialogManager = dialogManager
        self.sessionManager = sessionManager
        
        contextManager.add(delegate: self)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
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
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        self.options = options
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
            self.dialogManager.removeAttributes()
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
    func endPointDetectorDidError() {
        asrDispatchQueue.async { [weak self] in
            self?.asrResult = .error(ASRError.listenFailed)
        }
    }
    
    func endPointDetectorStateChanged(_ state: EndPointDetectorState) {
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
            case .end, .reachToMaxLength, .finish:
                self.executeStopSpeech()
            case .unknown:
                self.asrResult = .error(ASRError.recognizeFailed)
            case .timeout:
                self.asrResult = .error(ASRError.listeningTimeout)
            }
        }
    }
    
    func endPointDetectorSpeechDataExtracted(speechData: Data) {
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
            
            let attachmentHeader = Upstream.Attachment.Header(seq: self.attachmentSeq, isEnd: false, type: "audio/speex", messageId: TimeUUID().hexString)
            let attachment = Upstream.Attachment(content: speechData, header: attachmentHeader)
            self.upstreamDataSender.sendStream(attachment, dialogRequestId: asrRequest.dialogRequestId)
            self.attachmentSeq += 1
            log.debug("request seq: \(self.attachmentSeq-1)")
        }
    }
}

// MARK: - Private (Directive)

private extension ASRAgent {
    func prefetchExpectSpeech() -> PrefetchDirective {
        return { [weak self] directive in
            let expectSpeech = try JSONDecoder().decode(ASRExpectSpeech.self, from: directive.payload)

            self?.asrDispatchQueue.async { [weak self] in
                let attributes: [String: AnyHashable?] = [
                    "asrContext": expectSpeech.asrContext,
                    "domainTypes": expectSpeech.domainTypes,
                    "playServiceId": expectSpeech.playServiceId
                ]
                self?.dialogManager.setAttributes(attributes.compactMapValues { $0 })
            }
        }
    }

    func handleExpectSpeech() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }
        
            self?.asrDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard self.dialogManager.attributes != nil else {
                    log.error("Dialog attributes is nil")
                    return
                }
                guard [.idle, .busy].contains(self.asrState) else {
                    log.error("ExpectSpeech only allowed in IDLE or BUSY state.")
                    return
                }
                
                self.asrState = .expectingSpeech
                self.expectingSpeechTimeout = Observable<Int>
                    .timer(ASRConst.focusTimeout, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                    .subscribe(onNext: { [weak self] _ in
                        log.info("expectingSpeechTimeout")
                        self?.asrResult = .error(ASRError.listenFailed)
                    })
                self.expectingSpeechTimeout?.disposed(by: self.disposeBag)

                self.options.initiator = .scenario
                self.startRecognition(options: self.options, by: directive)
            }
        }
    }
    
    func handleNotifyResult() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion() }

            guard let item = try? JSONDecoder().decode(ASRNotifyResult.self, from: directive.payload) else {
                log.error("Invalid payload")
                return
            }
            
            self?.asrDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.endPointDetector?.handleNotifyResult(item.state)
                switch item.state {
                case .partial:
                    self.asrResult = .partial(text: item.result ?? "")
                case .complete:
                    self.asrResult = .complete(text: item.result ?? "")
                case .none:
                    self.asrResult = .none
                case .error:
                    self.asrResult = .error(ASRError.recognizeFailed)
                default:
                    // TODO 추후 Server EPD 개발시 구현
                    break
                }
            }
        }
    }
}

// MARK: - Private (Event)

private extension ASRAgent {
    func sendEvent(
        typeInfo: Event.TypeInfo,
        referrerDialogRequestId: String
    ) {
        contextManager.getContexts(namespace: capabilityAgentProperty.name) { [weak self] contextPayload in
            guard let self = self else { return }
            
            self.upstreamDataSender.sendEvent(
                Event(
                    typeInfo: typeInfo,
                    dialogAttributes: self.dialogManager.attributes
                ).makeEventMessage(
                    property: self.capabilityAgentProperty,
                    referrerDialogRequestId: referrerDialogRequestId,
                    contextPayload: contextPayload
                )
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
        
        asrState = .listening
        upstreamDataSender.sendStream(
            Event(
                typeInfo: .recognize(options: asrRequest.options),
                dialogAttributes: dialogManager.attributes
            ).makeEventMessage(
                property: self.capabilityAgentProperty,
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
                    
                    asrRequest.completion?(state)
                }
        }
        
        attachmentSeq = 0
        switch asrRequest.options.endPointing {
        case .client(let epdFile):
            endPointDetector = ClientEndPointDetector(asrOptions: asrRequest.options, epdFile: epdFile)
        case .server:
            endPointDetector = ServerEndPointDetector(asrOptions: asrRequest.options)

            // send wake up voice data
            if case let .wakeUpKeyword(_, data, _, _, _) = asrRequest.options.initiator {
                do {
                    let speexData = try SpeexEncoder(sampleRate: Int(asrRequest.options.sampleRate), inputType: .linearPcm16).encode(data: data)
                    
                    endPointDetectorSpeechDataExtracted(speechData: speexData)
                } catch {
                    log.error(error)
                }
            }
        }
        endPointDetector?.delegate = self
        endPointDetector?.start(audioStreamReader: asrRequest.reader)
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

        let attachmentHeader = Upstream.Attachment.Header(seq: self.attachmentSeq, isEnd: true, type: "audio/speex", messageId: TimeUUID().hexString)
        let attachment = Upstream.Attachment(content: Data(), header: attachmentHeader)
        upstreamDataSender.sendStream(attachment, dialogRequestId: asrRequest.dialogRequestId)
    }
    
    @discardableResult func startRecognition(
        options: ASROptions,
        by directive: Downstream.Directive?,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        log.debug("startRecognition, initiator: \(options.initiator)")
        let dialogRequestId = TimeUUID().hexString
        if options.endPointing == .server {
            log.warning("Server side end point detector does not support yet.")
            completion?(.error(ASRError.listenFailed))
            return dialogRequestId
        }
        // reader 는 최대한 빨리 만들어줘야 Data 유실이 없음.
        let reader = audioStream.makeAudioStreamReader()
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }

            guard [.listening, .recognizing, .busy].contains(self.asrState) == false else {
                log.warning("Not permitted in current state \(self.asrState)")
                completion?(.error(ASRError.listenFailed))
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
