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

import RxSwift

public class DirectiveSequencer: DirectiveSequenceable {
    private let prefetchDirectiveSubject = PublishSubject<Downstream.Directive>()
    private let handleDirectiveSubject = PublishSubject<Downstream.Directive>()
    private var directiveHandleInfos = DirectiveHandleInfos()
    private let directiveSequencerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.directive_sequencer", qos: .utility)
    private let disposeBag = DisposeBag()

    public init() {
        prefetchDirective()
        handleDirective()
    }
}

// MARK: - DirectiveSequenceable

public extension DirectiveSequencer {
    func add(directiveHandleInfos: DirectiveHandleInfos) {
        log.debug("add directive handles: \(directiveHandleInfos)")
        self.directiveHandleInfos.merge(directiveHandleInfos)
    }
    
    func remove(directiveHandleInfos: DirectiveHandleInfos) {
        log.debug("remove directive handles: \(directiveHandleInfos)")
        directiveHandleInfos.keys.forEach { key in
            self.directiveHandleInfos.removeValue(forKey: key)
        }
    }
    
    func processDirective(_ directive: Downstream.Directive) {
        log.info("\(directive.header.messageId)")
        guard directiveHandleInfos[directive.header.type] != nil else {
            log.warning("No handler registered \(directive.header.messageId)")
            return
        }

        prefetchDirectiveSubject.onNext(directive)
    }
    
    func processAttachment(_ attachment: Downstream.Attachment) {
        log.info("attachment messageId: \(attachment.header.messageId)")
        guard let handler = directiveHandleInfos[attachment.header.type] else {
            log.warning("No handler registered \(attachment.header.messageId)")
            return
        }
        
        // DirectiveSequencer 에서는 pass through. Attachment 에 대한 Validate 는 CA 에서 처리한다.
        directiveSequencerDispatchQueue.async {
            handler.attachmentHandler?(attachment)
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
                    let disposable = Disposables.create()
                    
                    guard let preFetch = self?.directiveHandleInfos[directive.header.type]?.preFetch else {
                        event(.success(.failure(HandleDirectiveError.handlerNotFound(type: directive.header.type))))
                        return disposable
                    }
                    
                    preFetch(directive) { result in
                        event(.success(result))
                    }
                    
                    return disposable
                }).do(onSuccess: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success:
                        self.handleDirectiveSubject.onNext(directive)
                    case .failure(let error):
                        log.error(error)
                    }
                })
            })
            .do(onError: {
                log.error($0)
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
        
        var handlingTypeInfos = [DirectiveHandleInfo]()
        var blockedDirectives = [DirectiveMedium: [Downstream.Directive]]()
        for medium in DirectiveMedium.allCases {
            blockedDirectives[medium] = []
        }

        let remove: (DirectiveHandleInfo) -> Void = { [weak self] typeInfo in
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
                guard let handler = self.directiveHandleInfos[directive.header.type] else {
                    log.error("No handler registered \(directive.header.messageId)")
                    return
                }
                
                // Block 되어야 하는 Directive 인지 확인
                guard handlingTypeInfos.isBlock(medium: handler.medium) == false else {
                    log.debug("Block directive \(directive.header.messageId)")
                    blockedDirectives[handler.medium]?.append(directive)
                    return
                }

                handlingTypeInfos.append(handler)
                
                handler.directiveHandler(directive) {
                    remove(handler)
                    if case .failure(let error) = $0 {
                        log.error(error)
                    }
                }
            }, onError: {
                log.error($0)
            })
            .retry()
            .subscribe().disposed(by: disposeBag)
    }
}
