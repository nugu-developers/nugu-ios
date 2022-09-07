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
import AVFoundation

import NuguCore
import NuguUtils
import JadeMarble

import RxSwift

public final class ASRAgent: ASRAgentProtocol {
    // CapabilityAgentable
    // TODO: ASR interface version 1.1 -> ASR.Recognize(wakeup/power)
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .automaticSpeechRecognition, version: "1.7")
    private let playSyncProperty = PlaySyncProperty(layerType: .asr, contextType: .sound)
    
    // Private
    private let focusManager: FocusManageable
    private let contextManager: ContextManageable
    private let directiveSequencer: DirectiveSequenceable
    private let upstreamDataSender: UpstreamDataSendable
    private let dialogAttributeStore: DialogAttributeStoreable
    private let sessionManager: SessionManageable
    private let playSyncManager: PlaySyncManageable
    private let interactionControlManager: InteractionControlManageable
    
    private let eventTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        // IMF-fixdate https://tools.ietf.org/html/rfc7231#section-7.1.1.1
        dateFormatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        return dateFormatter
    }()
    
    private var endPointDetector: EndPointDetectable?
    
    private let asrDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.asr_agent", qos: .userInitiated)
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var playSyncObserver: Any?
    
    public var options: ASROptions = ASROptions(endPointing: .client)
    private(set) public var asrState: ASRState = .idle {
        didSet {
            log.info("From:\(oldValue) To:\(asrState)")
            
            // `ASRRequest` -> `FocusState` -> EndPointDetector` -> `ASRAgentDelegate`
            // release asrRequest
            if asrState == .idle {
                asrRequest = nil
                releaseFocusIfNeeded()
            }
            
            // Stop EPD
            if [.listening(), .recognizing].contains(asrState) == false {
                endPointDetector?.stop()
                endPointDetector?.delegate = nil
                endPointDetector = nil
            }
            
            // Notify delegates only if the agent's status changes.
            if oldValue != asrState {
                post(NuguAgentNotification.ASR.State(state: asrState))
            }
        }
    }
    
    private var asrResult: ASRResult? {
        didSet {
            guard let asrRequest = asrRequest, let asrResult = asrResult else {
                asrState = .idle
                expectSpeech = nil
                log.error("ASRRequest not exist")
                return
            }
            log.info("\(asrResult)")
            
            // `ASRState` -> Event -> `expectSpeechDirective` -> `ASRAgentDelegate`
            switch asrResult {
            case .none:
                expectSpeech = nil
            case .partial:
                break
            case .complete:
                expectSpeech = nil
            case .cancel:
                asrState = .idle
                upstreamDataSender.cancelEvent(dialogRequestId: asrRequest.eventIdentifier.dialogRequestId)
                sendCompactContextEvent(Event(
                    typeInfo: .stopRecognize,
                    dialogAttributes: expectSpeech?.messageId == nil ? nil : dialogAttributeStore.getAttributes(key: expectSpeech!.messageId),
                    referrerDialogRequestId: asrRequest.eventIdentifier.dialogRequestId
                ).rx)
                expectSpeech = nil
            case .cancelExpectSpeech:
                asrState = .idle
                sendCompactContextEvent(Event(
                    typeInfo: .listenFailed,
                    dialogAttributes: expectSpeech?.messageId == nil ? nil : dialogAttributeStore.getAttributes(key: expectSpeech!.messageId),
                    referrerDialogRequestId: asrRequest.referrerDialogRequestId
                ).rx)
                expectSpeech = nil
            case .error(let error, _):
                asrState = .idle
                switch error {
                case NetworkError.timeout:
                    sendCompactContextEvent(Event(
                        typeInfo: .responseTimeout,
                        dialogAttributes: expectSpeech?.messageId == nil ? nil : dialogAttributeStore.getAttributes(key: expectSpeech!.messageId),
                        referrerDialogRequestId: asrRequest.eventIdentifier.dialogRequestId
                    ).rx)
                case ASRError.listeningTimeout:
                    upstreamDataSender.cancelEvent(dialogRequestId: asrRequest.eventIdentifier.dialogRequestId)
                    sendFullContextEvent(Event(
                        typeInfo: .listenTimeout,
                        dialogAttributes: expectSpeech?.messageId == nil ? nil : dialogAttributeStore.getAttributes(key: expectSpeech!.messageId),
                        referrerDialogRequestId: asrRequest.eventIdentifier.dialogRequestId
                    ).rx)
                case ASRError.listenFailed:
                    upstreamDataSender.cancelEvent(dialogRequestId: asrRequest.eventIdentifier.dialogRequestId)
                    sendCompactContextEvent(Event(
                        typeInfo: .listenFailed,
                        dialogAttributes: expectSpeech?.messageId == nil ? nil : dialogAttributeStore.getAttributes(key: expectSpeech!.messageId),
                        referrerDialogRequestId: asrRequest.eventIdentifier.dialogRequestId
                    ).rx)
                case ASRError.recognizeFailed:
                    break
                default:
                    break
                }
                expectSpeech = nil
            }
            
            post(NuguAgentNotification.ASR.Result(result: asrResult, dialogRequestId: asrRequest.eventIdentifier.dialogRequestId))
        }
    }
    
    // For Recognize Event
    @Atomic private var asrRequest: ASRRequest?
    private var attachmentSeq: Int32 = 0
    
    private lazy var disposeBag = DisposeBag()
    private var expectSpeech: ASRExpectSpeech? {
        didSet {
            if oldValue?.messageId != expectSpeech?.messageId {
                log.debug("From:\(oldValue?.messageId ?? "nil") To:\(expectSpeech?.messageId ?? "nil")")
            }
            if let dialogRequestId = expectSpeech?.dialogRequestId {
                sessionManager.activate(dialogRequestId: dialogRequestId, category: .automaticSpeechRecognition)
                interactionControlManager.start(mode: .multiTurn, category: capabilityAgentProperty.category)
            } else if let messageId = oldValue?.messageId {
                playSyncManager.endPlay(property: playSyncProperty)
                dialogAttributeStore.removeAttributes(key: messageId)
                interactionControlManager.finish(mode: .multiTurn, category: capabilityAgentProperty.category)
            }
            if let dialogRequestId = oldValue?.dialogRequestId {
                sessionManager.deactivate(dialogRequestId: dialogRequestId, category: .automaticSpeechRecognition)
            }
        }
    }
    
    // Handleable Directives
    private lazy var handleableDirectiveInfos = [
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "ExpectSpeech",
            blockingPolicy: BlockingPolicy(medium: .audio, isBlocking: true),
            preFetch: prefetchExpectSpeech,
            cancelDirective: cancelExpectSpeech,
            directiveHandler: handleExpectSpeech
        ),
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "NotifyResult",
            blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false),
            directiveHandler: handleNotifyResult
        ),
        DirectiveHandleInfo(
            namespace: capabilityAgentProperty.name,
            name: "CancelRecognize",
            blockingPolicy: BlockingPolicy(medium: .none, isBlocking: false),
            directiveHandler: handleCancelRecognize
        )
    ]
    
    public init(
        focusManager: FocusManageable,
        upstreamDataSender: UpstreamDataSendable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable,
        dialogAttributeStore: DialogAttributeStoreable,
        sessionManager: SessionManageable,
        playSyncManager: PlaySyncManageable,
        interactionControlManager: InteractionControlManageable
    ) {
        self.focusManager = focusManager
        self.upstreamDataSender = upstreamDataSender
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.dialogAttributeStore = dialogAttributeStore
        self.sessionManager = sessionManager
        self.playSyncManager = playSyncManager
        self.interactionControlManager = interactionControlManager
        
        addPlaySyncObserver(playSyncManager)
        contextManager.addProvider(contextInfoProvider)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        if let playSyncObserver = playSyncObserver {
            notificationCenter.removeObserver(playSyncObserver)
        }
        
        contextManager.removeProvider(contextInfoProvider)
        directiveSequencer.remove(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        let payload: [String: AnyHashable?] = [
            "version": self.capabilityAgentProperty.version,
            "engine": "skt",
            "state": self.asrState.value,
            "initiator": self.asrRequest?.initiator.value
        ]
        completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload.compactMapValues { $0 }))
    }
}

// MARK: - ASRAgentProtocol

public extension ASRAgent {
    @discardableResult func startRecognition(
        initiator: ASRInitiator,
        completion: ((StreamDataState) -> Void)?
    ) -> String {
        log.debug("startRecognition, initiator: \(initiator)")
        let eventIdentifier = EventIdentifier()
        
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard [.listening(), .recognizing, .busy].contains(self.asrState) == false else {
                log.warning("Not permitted in current state \(self.asrState)")
                completion?(.error(ASRError.listenFailed))
                return
            }
         
            self.startRecognition(initiator: initiator, eventIdentifier: eventIdentifier, completion: completion)
        }
        
        return eventIdentifier.dialogRequestId
    }
    
    func stopSpeech() {
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
    
    func putAudioBuffer(buffer: AVAudioPCMBuffer) {
        endPointDetector?.putAudioBuffer(buffer: buffer)
    }
    
    func stopRecognition() {
        log.debug("")
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.expectSpeech = nil
            if self.asrState != .idle {
                self.asrResult = .cancel()
            }
        }
    }
}

// MARK: - FocusChannelDelegate

extension ASRAgent: FocusChannelDelegate {
    public func focusChannelPriority() -> FocusChannelPriority {
        switch asrRequest?.initiator {
        case .expectSpeech: return .dmRecognition
        default: return .userRecognition
        }
    }
    
    public func focusChannelDidChange(focusState: FocusState) {
        asrDispatchQueue.async { [weak self] in
            guard let self = self else { return }

            log.info("focus: \(focusState) asr state: \(self.asrState)")
            switch (focusState, self.asrState) {
            case (.foreground, let asrState) where [.idle, .expectingSpeech].contains(asrState):
                self.executeStartCapture()
            // Ignore (foreground, [listening, recognizing, busy])
            case (.foreground, _):
                break
            // Not permitted background
            case (_, let asrState) where [.listening(), .recognizing].contains(asrState):
                self.asrResult = .cancel()
            case (_, .expectingSpeech):
                self.asrResult = .cancelExpectSpeech
            case (.nothing, .idle) where self.asrRequest != nil:
                // It might be error when focusState is nothing And AsrRequest does exist.
                self.asrResult = .error(ASRError.listenFailed)
            // Ignore prepare
            default:
                break
            }
        }
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
                log.info("Not permitted in current state \(self.asrState)")
                return
            }
            
            switch state {
            case .idle:
                self.asrResult = .error(ASRError.listenFailed)
            case .listening:
                break
            case .start:
                self.asrState = .recognizing
            case .end, .reachToMaxLength, .finish:
                self.executeStopSpeech()
            case .unknown:
                self.asrResult = .error(ASRError.listenFailed)
            case .timeout:
                self.asrResult = .error(ASRError.listeningTimeout(listenTimeoutFailBeep: self.expectSpeech?.payload.listenTimeoutFailBeep ?? true))
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
            
            let attachment = Attachment(typeInfo: .recognize).makeAttachmentMessage(
                property: self.capabilityAgentProperty,
                dialogRequestId: asrRequest.eventIdentifier.dialogRequestId,
                referrerDialogRequestId: asrRequest.referrerDialogRequestId,
                attachmentSeq: self.attachmentSeq,
                isEnd: false,
                speechData: speechData
            )
            self.upstreamDataSender.sendStream(attachment)
            self.attachmentSeq += 1
            log.debug("request seq: \(self.attachmentSeq-1)")
        }
    }
}

// MARK: - Private (Directive)

private extension ASRAgent {
    func prefetchExpectSpeech() -> PrefetchDirective {
        return { [weak self] directive in
            let payload = try JSONDecoder().decode(ASRExpectSpeech.Payload.self, from: directive.payload)

            self?.asrDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                if let playServiceId = payload.playServiceId {
                    self.playSyncManager.startPlay(
                        property: self.playSyncProperty,
                        info: PlaySyncInfo(
                            playStackServiceId: playServiceId,
                            dialogRequestId: directive.header.dialogRequestId,
                            messageId: directive.header.messageId,
                            duration: NuguTimeInterval(seconds: 0)
                        )
                    )
                }
                self.expectSpeech = ASRExpectSpeech(messageId: directive.header.messageId, dialogRequestId: directive.header.dialogRequestId, payload: payload)
                let attributes: [String: AnyHashable?] = [
                    "asrContext": payload.asrContext,
                    "domainTypes": payload.domainTypes,
                    "playServiceId": payload.playServiceId
                ]
                self.dialogAttributeStore.setAttributes(attributes.compactMapValues { $0 }, key: directive.header.messageId)
            }
        }
    }

    func handleExpectSpeech() -> HandleDirective {
        return { [weak self] directive, completion in
            defer { completion(.finished) }
            
            self?.asrDispatchQueue.sync { [weak self] in
                guard let self = self else { return }
                // ex> TTS 도중 stopRecognition 호출.
                guard let expectSpeech = self.expectSpeech, expectSpeech.messageId == directive.header.messageId else {
                    log.info("Message id does not match")
                    return
                }
                // ex> TTS 도중 wakeup
                guard [.idle, .busy].contains(self.asrState) else {
                    log.warning("ExpectSpeech only allowed in IDLE or BUSY state.")
                    return
                }
                
                self.asrState = .expectingSpeech
                self.startRecognition(initiator: .expectSpeech, eventIdentifier: EventIdentifier(), completion: nil)
            }
        }
    }
    
    func cancelExpectSpeech() -> CancelDirective {
        return { [weak self] directive in
            self?.asrDispatchQueue.async { [weak self] in
                if self?.expectSpeech?.dialogRequestId == directive.header.dialogRequestId {
                    self?.expectSpeech = nil
                }
            }
        }
    }
    
    func handleNotifyResult() -> HandleDirective {
        return { [weak self] directive, completion in
            guard let item = try? JSONDecoder().decode(ASRNotifyResult.self, from: directive.payload) else {
                completion(.failed("Invalid payload"))
                return
            }
            defer { completion(.finished) }

            self?.asrDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.endPointDetector?.handleNotifyResult(item.state)
                switch item.state {
                case .partial:
                    self.asrResult = .partial(text: item.result ?? "", header: directive.header)
                case .complete:
                    self.asrResult = .complete(text: item.result ?? "", header: directive.header)
                case .none:
                    self.asrResult = .none(header: directive.header)
                case .error:
                    self.asrResult = .error(ASRError.recognizeFailed, header: directive.header)
                default:
                    // TODO: after server preparation.
                    break
                }
            }
        }
    }
    
    func handleCancelRecognize() -> HandleDirective {
        return { [weak self] _, completion in
            guard let self = self else {
                completion(.canceled)
                return
            }
            
            self.asrDispatchQueue.async { [weak self] in
                guard let self = self else {
                    completion(.canceled)
                    return
                }
                defer { completion(.finished) }
                
                if self.asrState != .idle {
                    self.asrResult = .cancel()
                }
            }
        }
    }
}

// MARK: - Private (Event)

private extension ASRAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: self.capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
    
    @discardableResult func sendFullContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(),
            property: self.capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
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
            asrResult = .cancel()
            return
        }
        
        asrRequest.completion?(.prepared)
        
        var httpHeaderFields = [String: String]()
        if let lastAsrEventTime = UserDefaults.Nugu.lastAsrEventTime {
            httpHeaderFields["Last-Asr-Event-Time"] = lastAsrEventTime
        }
        upstreamDataSender.sendStream(
            Event(
                typeInfo: .recognize(initiator: asrRequest.initiator, options: asrRequest.options),
                dialogAttributes: dialogAttributeStore.requestAttributes(key: expectSpeech?.messageId),
                referrerDialogRequestId: asrRequest.referrerDialogRequestId
            ).makeEventMessage(
                property: self.capabilityAgentProperty,
                eventIdentifier: asrRequest.eventIdentifier,
                httpHeaderFields: httpHeaderFields,
                contextPayload: asrRequest.contextPayload
        )) { [weak self] (state) in
                self?.asrDispatchQueue.async { [weak self] in
                    guard self?.asrRequest?.eventIdentifier == asrRequest.eventIdentifier else { return }
                    
                    switch state {
                    case .finished:
                        self?.asrState = .idle
                    case .error(let error):
                        self?.asrResult = .error(error)
                    case .sent:
                        self?.asrState = .listening(initiator: asrRequest.initiator)
                        if let formatter = self?.eventTimeFormatter {
                            UserDefaults.Nugu.lastAsrEventTime = formatter.string(from: Date())
                        }
                    default:
                        break
                    }
                    
                    asrRequest.completion?(state)
                }
        }
        
        attachmentSeq = 0
        switch asrRequest.options.endPointing {
        case .client:
            endPointDetector = ClientEndPointDetector(asrOptions: asrRequest.options)
        case .server:
            // TODO: after server preparation.
            log.error("Server side end point detector does not support yet.")
            asrResult = .error(ASRError.listenFailed)
//            endPointDetector = ServerEndPointDetector(asrOptions: asrRequest.options)
//
//            // send wake up voice data
//            if case let .wakeUpWord(_, data, _, _, _) = asrRequest.options.initiator {
//                do {
//                    let speexData = try SpeexEncoder(sampleRate: Int(asrRequest.options.sampleRate), inputType: .linearPcm16).encode(data: data)
//
//                    endPointDetectorSpeechDataExtracted(speechData: speexData)
//                } catch {
//                    log.error(error)
//                }
//            }
        }
        endPointDetector?.delegate = self
        endPointDetector?.start()
    }
    
    /// asrDispatchQueue
    func executeStopSpeech() {
        guard let asrRequest = asrRequest else {
            log.error("ASRRequest not exist")
            asrResult = .cancel()
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

        let attachment = Attachment(typeInfo: .recognize).makeAttachmentMessage(
            property: self.capabilityAgentProperty,
            dialogRequestId: asrRequest.eventIdentifier.dialogRequestId,
            referrerDialogRequestId: asrRequest.referrerDialogRequestId,
            attachmentSeq: self.attachmentSeq,
            isEnd: true,
            speechData: Data()
        )
        upstreamDataSender.sendStream(attachment)
    }
    
    /// asrDispatchQueue
    func startRecognition(
        initiator: ASRInitiator,
        eventIdentifier: EventIdentifier,
        completion: ((StreamDataState) -> Void)?
    ) {
        let semaphore = DispatchSemaphore(value: 0)
        let options: ASROptions
        if let epd = self.expectSpeech?.payload.epd {
            options = ASROptions(
                maxDuration: epd.maxDuration ?? self.options.maxDuration,
                timeout: epd.timeout ?? self.options.timeout,
                pauseLength: epd.pauseLength ?? self.options.pauseLength,
                encoding: self.options.encoding,
                endPointing: self.options.endPointing
            )
        } else {
            options = self.options
        }
        asrRequest = ASRRequest(
            eventIdentifier: eventIdentifier,
            initiator: initiator,
            options: options,
            referrerDialogRequestId: expectSpeech?.dialogRequestId,
            completion: completion
        )
        self.contextManager.getContexts { [weak self] contextPayload in
            defer {
                semaphore.signal()
            }
            
            guard let self = self else { return }
            
            self.asrRequest?.contextPayload = contextPayload
            self.focusManager.requestFocus(channelDelegate: self)
        }
        
        semaphore.wait()
    }
}

// MARK: - Observers

extension Notification.Name {
    static let asrAgentStartRecognition = Notification.Name("com.sktelecom.romaine.notification.name.asr_agent_start_recognition")
    static let asrAgentStateDidChange = Notification.Name("com.sktelecom.romaine.notification.name.asr_agent_state_did_chage")
    static let asrAgentResultDidReceive = Notification.Name("com.sktelecom.romaine.notification.name.asr_agent_result_did_receive")
}

public extension NuguAgentNotification {
    enum ASR {
        public struct StartRecognition: TypedNotification {
            public static let name: Notification.Name = .asrAgentStartRecognition
            public let dialogRequestId: String

            public static func make(from: [String: Any]) -> StartRecognition? {
                guard let dialogRequestId = from["dialogRequestId"] as? String else { return nil }

                return StartRecognition(dialogRequestId: dialogRequestId)
            }
        }
        
        public struct State: TypedNotification {
            public static let name: Notification.Name = .asrAgentStateDidChange
            public let state: ASRState
            
            public static func make(from: [String: Any]) -> State? {
                guard let state = from["state"] as? ASRState else { return nil }
                
                return State(state: state)
            }
        }
        
        public struct Result: TypedNotification {
            public static let name: Notification.Name = .asrAgentResultDidReceive
            public let result: ASRResult
            public let dialogRequestId: String
            
            public static func make(from: [String: Any]) -> Result? {
                guard let result = from["result"] as? ASRResult,
                      let dialogRequestId = from["dialogRequestId"] as? String else { return nil }
                
                return Result(result: result, dialogRequestId: dialogRequestId)
            }
        }
    }
}

private extension ASRAgent {
    func addPlaySyncObserver(_ object: PlaySyncManageable) {
        playSyncObserver = object.observe(NuguCoreNotification.PlaySync.ReleasedProperty.self, queue: nil) { [weak self] (notification) in
            self?.asrDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                guard notification.property == self.playSyncProperty, self.expectSpeech?.messageId == notification.messageId else { return }
                
                self.stopRecognition()
            }
        }
    }
}
