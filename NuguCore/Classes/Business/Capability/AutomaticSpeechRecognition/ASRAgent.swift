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

final public class ASRAgent: ASRAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .automaticSpeechRecognition, version: "1.0")
    
    private let asrDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.asr_agent", qos: .userInitiated)
    
    public var focusManager: FocusManageable!
    public var channel: FocusChannelConfigurable!
    public var messageSender: MessageSendable!
    public var contextManager: ContextManageable!
    public var audioStream: AudioStreamable!
    public var endPointDetector: EndPointDetectable! {
        didSet {
            endPointDetector?.delegate = self
        }
    }
    public var dialogStateAggregator: DialogStateAggregatable!
    
    private let asrDelegates = DelegateSet<ASRAgentDelegate>()
    public weak var wakeUpInfoDelegate: WakeUpInfoDelegate?
    
    private var focusState: FocusState = .nothing
    private var asrState: ASRState = .idle {
        didSet {
            log.info("\(oldValue) \(asrState)")
            guard oldValue != asrState else { return }
            
            // dispose expectingSpeechTimeout
            if asrState != .expectingSpeech {
                expectingSpeechTimeout?.dispose()
            }
            
            // dispose responseTimeout
            if asrState != .busy {
                responseTimeout?.dispose()
            }
            
            // release asrRequest
            if asrState == .idle {
                asrRequest = nil
            }
            
            // Stop EPD
            switch (asrState, endPointDetector.state) {
            case (let asrState, _) where [.listening, .recognizing].contains(asrState):
                break
            case (_, let epdState) where [.start, .listening].contains(epdState):
                endPointDetector.stop()
            default:
                break
            }
            
            asrDelegates.notify { delegate in
                delegate.asrAgentDidChange(state: asrState)
            }
        }
    }
    private var asrResult: ASRResult = .none {
        didSet {
            log.info("\(oldValue) \(asrResult)")
            guard oldValue != asrResult else { return }
            
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
                releaseFocus()
                currentExpectSpeech = nil
            case .error(let error):
                switch error {
                case .responseTimeout:
                    sendEvent(event: .responseTimeout)
                case .listeningTimeout:
                    sendEvent(event: .listenTimeout)
                case .listenFailed:
                    if let asrRequest = asrRequest {
                        sendEvent(event: .listenFailed, dialogRequestId: asrRequest.dialogRequestId)
                    } else {
                        self.sendEvent(event: .listenFailed, dialogRequestId: TimeUUID().hexString)
                    }
                case .recognizeFailed:
                    break
                }
                releaseFocus()
                currentExpectSpeech = nil
            }
            
            self.asrDelegates.notify({ (delegate) in
                delegate.asrAgentDidReceive(result: asrResult)
            })
        }
    }
    
    // For Recognize Event
    private var asrRequest: ASRRequest?
    private var attachmentSeq: Int32 = 0
    private var currentExpectSpeech: ASRExpectSpeech? {
        didSet {
            dialogStateAggregator.expectSpeech = currentExpectSpeech
        }
    }
    
    private lazy var disposeBag = DisposeBag()
    private var expectingSpeechTimeout: Disposable?
    private var responseTimeout: Disposable?
    
    public init() {
        log.info("")
    }
    
    deinit {
        log.info("")
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
        // reader 는 최대한 빨리 만들어줘야 Data 유실이 없음.
        let reader = self.audioStream.makeAudioStreamReader()
        
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch self.asrState {
            case .idle, .expectingSpeech:
                break
            case .listening, .recognizing, .busy:
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
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
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
    public func handleDirectiveTypeInfos() -> DirectiveTypeInfos {
        return DirectiveTypeInfo.allDictionaryCases
    }
    
    public func handleDirectivePrefetch(
        _ directive: DirectiveProtocol,
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
        _ directive: DirectiveProtocol,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        let result = Result<DirectiveTypeInfo, Error> (catching: {
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
    public func focusChannelConfiguration() -> FocusChannelConfigurable {
        return channel
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("\(focusState) \(asrState)")
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
            case (.background, _):
                self.asrResult = .cancel
            case (.nothing, _):
                self.asrState = .idle
            }
        }
    }
}

// MARK: - ProvideContextDelegate

extension ASRAgent: ProvideContextDelegate {
    public func provideContext() -> ContextInfo {
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
            self?.asrResult = .error(.listenFailed)
        }
    }
    
    public func endPointDetectorStateChanged(state: EndPointDetectorState) {
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
                self.asrResult = .error(.listeningTimeout)
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
                dialogRequestId: asrRequest.dialogRequestId
            )
            let attachment = UpstreamAttachment(header: attachmentHeader, content: speechData, seq: self.attachmentSeq, isEnd: false)
            self.messageSender.send(upstreamAttachment: attachment)
            self.attachmentSeq += 1
            log.debug("request seq: \(self.attachmentSeq-1)")
        }
    }
}

// MARK: - ReceiveMessageDelegate

extension ASRAgent: ReceiveMessageDelegate {
    public func receiveMessageDidReceive(directive: DirectiveProtocol) {
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let request = self.asrRequest else { return }
            guard directive.header.type != DirectiveTypeInfo.notifyResult.type else { return }
            guard request.dialogRequestId == directive.header.dialogRequestID else { return }
            
            switch self.asrState {
            case .busy, .expectingSpeech:
                self.releaseFocus()
            case .idle, .listening, .recognizing:
                return
            }
        }
    }
}

// MARK: - Private (Directive)

private extension ASRAgent {
    func prefetchExpectSpeech(directive: DirectiveProtocol) -> Result<Void, Error> {
        return Result { [weak self] in
            guard let data = directive.payload.data(using: .utf8) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
            }
         
            self?.currentExpectSpeech = try JSONDecoder().decode(ASRExpectSpeech.self, from: data)
        }
    }

    func expectSpeech(directive: DirectiveProtocol) -> Result<Void, Error> {
        return Result { [weak self] in
            guard currentExpectSpeech != nil else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
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
                        self?.asrResult = .error(.listenFailed)
                    })
                self.expectingSpeechTimeout?.disposed(by: self.disposeBag)
                
                self.startRecognition()
            }
        }
    }
    
    func notifyResult(directive: DirectiveProtocol) -> Result<Void, Error> {
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
                    self.asrResult = .error(.recognizeFailed)
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
    func sendRequestEvent(asrRequest: ASRRequest, completion: ((SendMessageStatus) -> Void)? = nil) {
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
//             KeyWordDetector's use 16k mono (bit depth: 16).
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
            by: messageSender,
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
    
    func sendEndOfSpeechAttachment(asrRequest: ASRRequest) {
        let attachmentHeader = UpstreamHeader(
            namespace: capabilityAgentProperty.name,
            name: "Recognize",
            version: capabilityAgentProperty.version,
            dialogRequestId: asrRequest.dialogRequestId
        )
        let attachment = UpstreamAttachment(header: attachmentHeader, content: Data(), seq: attachmentSeq, isEnd: true)
        messageSender.send(upstreamAttachment: attachment)
    }
    
    func sendEvent(event: ASRAgent.Event.TypeInfo) {
        guard let asrRequest = asrRequest else {
            log.warning("ASRRequest not exist")
            return
        }
        
        sendEvent(event: event, dialogRequestId: asrRequest.dialogRequestId)
    }
    
    func sendEvent(event: ASRAgent.Event.TypeInfo, dialogRequestId: String) {
        sendEvent(
            Event(typeInfo: event, expectSpeech: currentExpectSpeech),
            context: provideContext(),
            dialogRequestId: dialogRequestId,
            by: messageSender
        )
    }
}

// MARK: - Private(FocusManager)

private extension ASRAgent {
    func releaseFocus() {
        guard focusState != .nothing else { return }
        focusManager.releaseFocus(channelDelegate: self)
    }
}

// MARK: - Private(EndPointDetector)

private extension ASRAgent {
    /// asrDispatchQueue
    func executeStartCapture() {
        guard let asrRequest = asrRequest else {
            log.warning("ASRRequest not exist")
            asrResult = .cancel
            return
        }
        
        do {
            attachmentSeq = 0
            if let timeout = currentExpectSpeech?.timeoutInMilliseconds {
                try endPointDetector.start(inputStream: asrRequest.reader, timeout: timeout / 1000)
            } else {
                try endPointDetector.start(inputStream: asrRequest.reader)
            }

            sendRequestEvent(asrRequest: asrRequest) { [weak self] (status) in
                guard case .success = status else {
                    self?.asrResult = .error(.recognizeFailed)
                    return
                }
                
                self?.asrState = .listening
            }
        } catch {
            log.error(error)
            asrResult = .error(.listenFailed)
        }
    }
    
    /// asrDispatchQueue
    func executeStopSpeech() {
        guard let asrRequest = asrRequest else {
            log.warning("ASRRequest not exist")
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
        
        responseTimeout?.dispose()
        responseTimeout = Observable<Int>
            .timer(NuguApp.shared.configuration.asrResponseTimeout, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
            .subscribe(onNext: { [weak self] _ in
                self?.asrResult = .error(.responseTimeout)
            })
        self.responseTimeout?.disposed(by: self.disposeBag)
        
        sendEndOfSpeechAttachment(asrRequest: asrRequest)
    }
}
