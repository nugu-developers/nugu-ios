//
//  ASRAgent.swift
//  NuguCore
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

import NuguInterface

import RxSwift

final public class ASRAgent: ASRAgentProtocol, CapabilityDirectiveAgentable, CapabilityEventAgentable, CapabilityFocusAgentable {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .automaticSpeechRecognition, version: "1.0")
    
    // CapabilityFocusAgentable
    public let focusManager: FocusManageable
    public let channelPriority: FocusChannelPriority
    
    // CapabilityEventAgentable
    public let upstreamDataSender: UpstreamDataSendable
    
    // WakeUpInfoDelegate(KeenSense)
    public weak var wakeUpInfoDelegate: WakeUpInfoDelegate?
    
    // Private
    private let contextManager: ContextManageable
    private let audioStream: AudioStreamable
    fileprivate static var endPointDetector: EndPointDetector?
    
    private let asrDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.asr_agent", qos: .userInitiated)
    
    private let asrDelegates = DelegateSet<ASRAgentDelegate>()
    
    private var focusState: FocusState = .nothing
    private var asrState: ASRState = .idle {
        didSet {
            log.info("From:\(oldValue) To:\(asrState)")
            guard oldValue != asrState else { return }
            
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
            
            asrDelegates.notify { delegate in
                delegate.asrAgentDidChange(state: asrState, expectSpeech: currentExpectSpeech)
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
            
            switch asrResult {
            case .none:
                // Focus 는 결과 directive 받은 후 release 해주어야 함.
                currentExpectSpeech = nil
            case .partial:
                break
            case .complete:
                // Focus 는 결과 directive 받은 후 release 해주어야 함.
                currentExpectSpeech = nil
            case .cancel:
                sendEvent(event: .stopRecognize)
                currentExpectSpeech = nil
                asrState = .idle
            case .error(let error):
                switch error {
                case NetworkError.timeout:
                    sendEvent(event: .responseTimeout)
                case ASRError.listeningTimeout:
                    sendEvent(event: .listenTimeout)
                case ASRError.listenFailed:
                    sendEvent(event: .listenFailed)
                case ASRError.recognizeFailed:
                    break
                default:
                    break
                }
                currentExpectSpeech = nil
                asrState = .idle
            }
            
            self.asrDelegates.notify({ (delegate) in
                delegate.asrAgentDidReceive(result: asrResult, dialogRequestId: asrRequest.dialogRequestId)
            })
        }
    }
    
    // For Recognize Event
    private var asrRequest: ASRRequest?
    private var attachmentSeq: Int32 = 0
    private var currentExpectSpeech: ASRExpectSpeech?
    
    private lazy var disposeBag = DisposeBag()
    private var expectingSpeechTimeout: Disposable?
    
    public init(
        focusManager: FocusManageable,
        channelPriority: FocusChannelPriority,
        upstreamDataSender: UpstreamDataSendable,
        contextManager: ContextManageable,
        audioStream: AudioStreamable,
        directiveSequencer: DirectiveSequenceable
    ) {
        Self.endPointDetector = EndPointDetector()
        
        self.focusManager = focusManager
        self.channelPriority = channelPriority
        self.upstreamDataSender = upstreamDataSender
        self.contextManager = contextManager
        self.audioStream = audioStream
        
        Self.endPointDetector?.delegate = self
        contextManager.add(provideContextDelegate: self)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(handleDirectiveDelegate: self)
    }
    
    deinit {
        Self.endPointDetector = nil
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
    
    func startRecognition() {
        log.debug("")
        // reader 는 최대한 빨리 만들어줘야 Data 유실이 없음.
        let reader = self.audioStream.makeAudioStreamReader()
        
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard [.listening, .recognizing, .busy].contains(self.asrState) == false else {
                log.warning("Not permitted in current state \(self.asrState)")
                return
            }
            
            self.contextManager.getContexts { [weak self] contextPayload in
                guard let self = self else { return }
                
                self.asrRequest = ASRRequest(
                    contextPayload: contextPayload,
                    reader: reader,
                    dialogRequestId: TimeUUID().hexString
                )
                
                self.focusManager.requestFocus(channelDelegate: self)
            }
        }
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
            self.currentExpectSpeech = nil
            guard self.asrState != .idle else {
                log.info("Not permitted in current state, \(self.asrState)")
                return
            }

            self.asrResult = .cancel
        }
    }
}

// MARK: - HandleDirectiveDelegate

extension ASRAgent: HandleDirectiveDelegate {
    public func handleDirectivePrefetch(
        _ directive: Downstream.Directive,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        switch directive.header.type {
        case DirectiveTypeInfo.expectSpeech.type:
            completionHandler(prefetchExpectSpeech(directive: directive))
        default:
            completionHandler(.success(()))
        }
    }
    
    public func handleDirective(
        _ directive: Downstream.Directive,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        let result = Result<DirectiveTypeInfo, Error>(catching: {
            guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Unknown directive")
            }
            
            return directiveTypeInfo
        }).flatMap({ (typeInfo) -> Result<Void, Error> in
            switch typeInfo {
            case .expectSpeech:
                return expectSpeech(directive: directive)
            case .notifyResult:
                return notifyResult(directive: directive)
            }
        })
        
        completionHandler(result)
    }
}

// MARK: - FocusChannelDelegate

extension ASRAgent: FocusChannelDelegate {
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("Focus:\(focusState) ASR:\(asrState)")
        self.focusState = focusState
        
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch (focusState, self.asrState) {
            case (.foreground, let asrState) where [.idle, .expectingSpeech].contains(asrState):
                self.executeStartCapture()
            // Listening, Recognizing, Busy 무시
            case (.foreground, _):
                break
            // Background 허용 안함.
            case (_, let asrState) where asrState != .idle:
                self.asrResult = .cancel
            default:
                break
            }
        }
    }
}

// MARK: - ContextInfoDelegate

extension ASRAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        let payload: [String: Any] = [
            "version": capabilityAgentProperty.version,
            "engine": "skt"
        ]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload)
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
            
            let attachmentHeader = UpstreamHeader(
                namespace: self.capabilityAgentProperty.name,
                name: "Recognize",
                version: self.capabilityAgentProperty.version,
                dialogRequestId: asrRequest.dialogRequestId,
                messageId: TimeUUID().hexString
            )
            let attachment = UpstreamAttachment(header: attachmentHeader, content: speechData, seq: self.attachmentSeq, isEnd: false)
            self.upstreamDataSender.send(upstreamAttachment: attachment, completion: nil, resultHandler: nil)
            self.attachmentSeq += 1
            log.debug("request seq: \(self.attachmentSeq-1)")
        }
    }
}

// MARK: - Private (Directive)

private extension ASRAgent {
    func prefetchExpectSpeech(directive: Downstream.Directive) -> Result<Void, Error> {
        return Result { [weak self] in
            guard let data = directive.payload.data(using: .utf8) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
            }
         
            self?.currentExpectSpeech = try JSONDecoder().decode(ASRExpectSpeech.self, from: data)
        }
    }

    func expectSpeech(directive: Downstream.Directive) -> Result<Void, Error> {
        return Result { [weak self] in
            guard currentExpectSpeech != nil else {
                throw HandleDirectiveError.handleDirectiveError(message: "currentExpectSpeech is nil")
            }
            switch asrState {
            case .idle, .busy:
                break
            case .expectingSpeech, .listening, .recognizing:
                throw HandleDirectiveError.handleDirectiveError(message: "ExpectSpeech only allowed in IDLE or BUSY state.")
            }
            
            self?.asrDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.asrState = .expectingSpeech
                self.expectingSpeechTimeout = Observable<Int>
                    .timer(ASRConst.focusTimeout, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                    .subscribe(onNext: { [weak self] _ in
                        log.info("expectingSpeechTimeout")
                        self?.asrResult = .error(ASRError.listenFailed)
                    })
                self.expectingSpeechTimeout?.disposed(by: self.disposeBag)
                
                self.startRecognition()
            }
        }
    }
    
    func notifyResult(directive: Downstream.Directive) -> Result<Void, Error> {
        return Result { [weak self] in
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
    }
}

// MARK: - Private (Event, Attachment)

private extension ASRAgent {
    func sendRequestEvent(asrRequest: ASRRequest, completion: ((Result<Data, Error>) -> Void)? = nil) {
        // TODO: 추후 server epd 구현되면 활성화
//        let wakeUpInfo: (Data, Int)?
//        if asrRequest.initiator == .wakeword {
//            wakeUpInfo = wakeUpInfoDelegate?.requestWakeUpInfo()
//        } else {
//            wakeUpInfo = nil
//        }
//
//        var eventWakeUpInfo: ASRAgent.Event.WakeUpInfo? {
//            guard let (data, padding) = wakeUpInfo else {
//                return nil
//            }
//
//            /**
//             KeywordDetector's use 16k mono (bit depth: 16).
//             so, You can calculate sample count by (dataCount / 2)
//             */
//            let totalFrameCount = data.count / 2
//            let paddingFrameCount = padding / 2
//            return Event.WakeUpInfo(start: 0, end: totalFrameCount - paddingFrameCount, detection: totalFrameCount)
//        }
//        let eventTypeInfo = Event.TypeInfo.recognize(wakeUpInfo: eventWakeUpInfo)
        
        let eventTypeInfo = Event.TypeInfo.recognize(wakeUpInfo: nil)
        sendEvent(
            Event(typeInfo: eventTypeInfo, expectSpeech: currentExpectSpeech),
            contextPayload: asrRequest.contextPayload,
            dialogRequestId: asrRequest.dialogRequestId,
            messageId: TimeUUID().hexString,
            completion: completion
        )

        // TODO: 추후 server epd 구현되면 활성화
        // send wake up voice data
//        if let (data, _) = wakeUpInfo {
//            if let speexData = try? SpeexEncoder(sampleRate: 16000, inputType: .linearPCM16).encode(data: data) {
//                let attachmentHeader = UpstreamHeader(
//                    namespace: capabilityAgentProperty.name,
//                    name: "Recognize",
//                    version: capabilityAgentProperty.version,
//                    dialogRequestId: asrRequest.dialogRequestId
//                )
//
//                let attachment = UpstreamAttachment(header: attachmentHeader, content: speexData, seq: attachmentSeq, isEnd: false)
//                messageSender.send(upstreamAttachment: attachment)
//
//                #if DEBUG
//                let wakeUpFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wakeUpVoice.speex")
//                do {
//                    try speexData.write(to: wakeUpFilename)
//                    log.debug("wake up voice file: \(wakeUpFilename)")
//                } catch {
//                    log.error("file write error: \(error)")
//                }
//                #endif
//            }
//        }
    }
    
    func sendEvent(event: ASRAgent.Event.TypeInfo) {
        guard let asrRequest = asrRequest else {
            log.warning("ASRRequest not exist")
            return
        }
        
        sendEvent(
            Event(typeInfo: event, expectSpeech: currentExpectSpeech),
            dialogRequestId: asrRequest.dialogRequestId,
            messageId: TimeUUID().hexString
        )
    }
}

// MARK: - Private(FocusManager)

private extension ASRAgent {
    func releaseFocusIfNeeded() {
        guard focusState != .nothing else { return }
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
            guard let expectTimeout = currentExpectSpeech?.timeoutInMilliseconds else {
                return ASRConst.timeout
            }
            
            return expectTimeout / 1000
        }
        
        Self.endPointDetector?.start(
            inputStream: asrRequest.reader,
            sampleRate: ASRConst.sampleRate,
            timeout: timeout,
            maxDuration: ASRConst.maxDuration,
            pauseLength: ASRConst.pauseLength
        )
        
        asrState = .listening
        
        sendRequestEvent(asrRequest: asrRequest) { [weak self] (status) in
            guard self?.asrRequest?.dialogRequestId == asrRequest.dialogRequestId else { return }
            guard case .success = status else {
                self?.asrResult = .error(ASRError.recognizeFailed)
                return
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
        
        let attachmentHeader = UpstreamHeader(
            namespace: capabilityAgentProperty.name,
            name: "Recognize",
            version: capabilityAgentProperty.version,
            dialogRequestId: asrRequest.dialogRequestId,
            messageId: TimeUUID().hexString
        )
        let attachment = UpstreamAttachment(header: attachmentHeader, content: Data(), seq: attachmentSeq, isEnd: true)
        upstreamDataSender.send(upstreamAttachment: attachment, completion: nil) { [weak self] result in
            guard let self = self else { return }
            guard asrRequest.dialogRequestId == self.asrRequest?.dialogRequestId else { return }
            
            switch result {
            case .success:
                self.asrState = .idle
            case .failure(let error):
                self.asrResult = .error(error)
            }
        }
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
