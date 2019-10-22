//
//  DirectiveSequencer.swift
//  NuguCore
//
//  Created by MinChul Lee on 10/04/2019.
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

public class DirectiveSequencer: DirectiveSequenceable {
    private let messageSender: MessageSendable
    
    private var handleDirectiveDelegates = DelegateDictionary<String, HandleDirectiveDelegate>()

    private let prefetchDirectiveSubject = PublishSubject<DirectiveProtocol>()
    private let handleDirectiveSubject = PublishSubject<DirectiveProtocol>()
    
    private var blockedDirectives = [DirectiveMedium: [DirectiveProtocol]]()
    
    private let directiveSequencerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.directive_sequencer", qos: .utility)

    private let disposeBag = DisposeBag()

    public init(messageSender: MessageSendable) {
        log.debug("")
        
        self.messageSender = messageSender

        prefetchDirective()
        handleDirective()
    }

    deinit {
        log.debug("")
    }
}

// MARK: - DirectiveSequenceable

extension DirectiveSequencer {
    public func add(handleDirectiveDelegate delegate: HandleDirectiveDelegate) throws {
        log.debug("\(delegate)")
        // Type 중복 체크
        let alreadySet = delegate.handleDirectiveTypeInfos().contains { key, _ -> Bool in
            return handleDirectiveDelegates[key] != nil
        }
        if alreadySet {
            throw DirectiveTypeInfoError.alreadySet
        }
        
        delegate.handleDirectiveTypeInfos().forEach { typeInfo in
            handleDirectiveDelegates[typeInfo.key] = delegate
        }
    }
    
    public func remove(handleDirectiveDelegate delegate: HandleDirectiveDelegate) throws {
        log.debug("\(delegate)")
        // TypeInfo 일치하는지 확인
        let notFound = delegate.handleDirectiveTypeInfos().contains { key, _ -> Bool in
            return handleDirectiveDelegates[key] == nil
        }
        if notFound {
            throw DirectiveTypeInfoError.notFound
        }
        
        delegate.handleDirectiveTypeInfos().forEach { typeInfo in
            handleDirectiveDelegates.removeValue(forKey: typeInfo.key)
        }
    }
}

// MARK: - ReceiveMessageDelegate

extension DirectiveSequencer: ReceiveMessageDelegate {
    public func receiveMessageDidReceive(directive: DirectiveProtocol) {
        log.info("\(directive.header.messageID)")
        guard handleDirectiveDelegates[directive.header.type] != nil else {
            messageSender.sendCrashReport(error: HandleDirectiveError.handlerNotFound(type: directive.header.type))
            log.warning("No handler registered \(directive.header.messageID)")
            return
        }

        prefetchDirectiveSubject.onNext(directive)
    }
    
    public func receiveMessageDidReceive(attachment: AttachmentProtocol) {
        log.info("\(attachment.header.messageID)")
        guard let handler = handleDirectiveDelegates[attachment.header.type] else {
            messageSender.sendCrashReport(error: HandleDirectiveError.handlerNotFound(type: attachment.header.type))
            log.warning("No handler registered \(attachment.header.messageID)")
            return
        }
        
        // DirectiveSequencer 에서는 pass through. Attachment 에 대한 Validate 는 CA 에서 처리한다.
        directiveSequencerDispatchQueue.async {
            handler.handleAttachment(attachment)
        }
    }
}

// MARK: - Private

private extension DirectiveSequencer {
    // Non-blocking 처리
    func prefetchDirective() {
        let prefetchHandleDirectiveScheduler = SerialDispatchQueueScheduler(
            queue: directiveSequencerDispatchQueue,
            internalSerialQueueName: "nugu.directive.prehandle"
        )
        
        prefetchDirectiveSubject.asObserver()
            .observeOn(prefetchHandleDirectiveScheduler)
            .concatMap({ [weak self] (directive) -> Single<Result<Void, Error>> in
                return Single.create(subscribe: { [weak self] (event) -> Disposable in
                    if let handler = self?.handleDirectiveDelegates[directive.header.type] {
                        handler.handleDirectivePrefetch(directive) { result in
                            event(.success(result))
                        }
                    } else {
                        event(.success(.failure(HandleDirectiveError.handlerNotFound(type: directive.header.type))))
                    }
                    return Disposables.create()
                }).do(onSuccess: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success:
                        self.handleDirectiveSubject.onNext(directive)
                    case .failure(let error):
                        self.messageSender.sendCrashReport(error: error)
                        log.error(error)
                    }
                })
            })
            .do(onError: { [weak self] error in
                self?.messageSender.sendCrashReport(error: error)
                log.error(error)
            })
            .retry()
            .subscribe().disposed(by: disposeBag)
    }
    
    // TypeInfo.isBlocking 인 경우 동일한 Medium 만 blocking 처리
    func handleDirective() {
        let handleDirectiveScheduler = SerialDispatchQueueScheduler(
            queue: directiveSequencerDispatchQueue,
            internalSerialQueueName: "nugu.directive.handle"
        )
        
        var handlingTypeInfos = [DirectiveTypeInforable]()
        for medium in DirectiveMedium.allCases {
            blockedDirectives[medium] = []
        }

        let remove: (DirectiveTypeInforable) -> Void = { [weak self] typeInfo in
            self?.directiveSequencerDispatchQueue.async { [weak self] in
                handlingTypeInfos.remove(element: typeInfo)
                
                // Block 된 Directive 다시시도.
                if typeInfo.isBlocking {
                    let directivies = self?.blockedDirectives[typeInfo.medium]
                    self?.blockedDirectives[typeInfo.medium]?.removeAll()
                    directivies?.forEach({ [weak self] directive in
                        self?.handleDirectiveSubject.onNext(directive)
                    })
                }
            }
        }
        
        handleDirectiveSubject.asObserver()
            .observeOn(handleDirectiveScheduler)
            .do(onNext: { [weak self] directive in
                guard let self = self else { return }
                guard
                    let handler = self.handleDirectiveDelegates[directive.header.type],
                    let typeInfo = handler.handleDirectiveTypeInfos()[directive.header.type] else {
                    log.warning("No handler registered \(directive.header.messageID)")
                    return
                }

                // Block 되어야 하는 Directive 인지 확인
                guard handlingTypeInfos.isBlock(medium: typeInfo.medium) == false else {
                    log.debug("Block directive \(directive.header.messageID)")
                    self.blockedDirectives[typeInfo.medium]?.append(directive)
                    return
                }

                handlingTypeInfos.append(typeInfo)
                handler.handleDirective(directive) { [weak self] result in
                    remove(typeInfo)
                    if case .failure(let error) = result {
                        self?.messageSender.sendCrashReport(error: error)
                        log.error(error)
                    }
                }
            }, onError: { [weak self] error in
                self?.messageSender.sendCrashReport(error: error)
                log.error(error)
            })
            .retry()
            .subscribe().disposed(by: disposeBag)
    }
}
