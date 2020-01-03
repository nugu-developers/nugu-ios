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
    private let upstreamDataSender: UpstreamDataSendable
    
    private var handleDirectiveDelegates = DelegateDictionary<String, HandleDirectiveDelegate>()

    private let prefetchDirectiveSubject = PublishSubject<Downstream.Directive>()
    private let handleDirectiveSubject = PublishSubject<Downstream.Directive>()
    
    private let directiveSequencerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.directive_sequencer", qos: .utility)

    private let disposeBag = DisposeBag()

    public init(upstreamDataSender: UpstreamDataSendable) {
        log.debug("")
        
        self.upstreamDataSender = upstreamDataSender

        prefetchDirective()
        handleDirective()
    }

    deinit {
        log.debug("")
    }
}

// MARK: - DirectiveSequenceable

extension DirectiveSequencer {
    public func add(handleDirectiveDelegate delegate: HandleDirectiveDelegate) {
        log.debug("\(delegate)")
        delegate.handleDirectiveTypeInfos().forEach { typeInfo in
            // Type 중복 체크
            if handleDirectiveDelegates[typeInfo.key] != nil {
                log.warning("Configuration was already set \(typeInfo.key)")
            } else {
                handleDirectiveDelegates[typeInfo.key] = delegate
            }
        }
    }
    
    public func remove(handleDirectiveDelegate delegate: HandleDirectiveDelegate) {
        log.debug("\(delegate)")
        delegate.handleDirectiveTypeInfos().forEach { typeInfo in
            handleDirectiveDelegates.removeValue(forKey: typeInfo.key)
        }
    }
}

// MARK: - DownstreamDataDelegate

extension DirectiveSequencer: DownstreamDataDelegate {
    public func downstreamDataDidReceive(directive: Downstream.Directive) {
        log.info("\(directive.header.messageId)")
        guard handleDirectiveDelegates[directive.header.type] != nil else {
            upstreamDataSender.sendCrashReport(error: HandleDirectiveError.handlerNotFound(type: directive.header.type))
            log.warning("No handler registered \(directive.header.messageId)")
            return
        }

        prefetchDirectiveSubject.onNext(directive)
    }
    
    public func downstreamDataDidReceive(attachment: Downstream.Attachment) {
        log.info("\(attachment.header.messageId)")
        guard let handler = handleDirectiveDelegates[attachment.header.type] else {
            upstreamDataSender.sendCrashReport(error: HandleDirectiveError.handlerNotFound(type: attachment.header.type))
            log.warning("No handler registered \(attachment.header.messageId)")
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
                        self.upstreamDataSender.sendCrashReport(error: error)
                        log.error(error)
                    }
                })
            })
            .do(onError: { [weak self] error in
                self?.upstreamDataSender.sendCrashReport(error: error)
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
        var blockedDirectives = [DirectiveMedium: [Downstream.Directive]]()
        for medium in DirectiveMedium.allCases {
            blockedDirectives[medium] = []
        }

        let remove: (DirectiveTypeInforable) -> Void = { [weak self] typeInfo in
            self?.directiveSequencerDispatchQueue.async { [weak self] in
                handlingTypeInfos.remove(element: typeInfo)
                
                // Block 된 Directive 다시시도.
                if typeInfo.isBlocking {
                    let directivies = blockedDirectives[typeInfo.medium]
                    blockedDirectives[typeInfo.medium]?.removeAll()
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
                    log.warning("No handler registered \(directive.header.messageId)")
                    return
                }

                // Block 되어야 하는 Directive 인지 확인
                guard handlingTypeInfos.isBlock(medium: typeInfo.medium) == false else {
                    log.debug("Block directive \(directive.header.messageId)")
                    blockedDirectives[typeInfo.medium]?.append(directive)
                    return
                }

                handlingTypeInfos.append(typeInfo)
                handler.handleDirective(directive) { [weak self] result in
                    remove(typeInfo)
                    if case .failure(let error) = result {
                        self?.upstreamDataSender.sendCrashReport(error: error)
                        log.error(error)
                    }
                }
            }, onError: { [weak self] error in
                self?.upstreamDataSender.sendCrashReport(error: error)
                log.error(error)
            })
            .retry()
            .subscribe().disposed(by: disposeBag)
    }
}
