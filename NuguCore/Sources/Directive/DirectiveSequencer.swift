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

import NuguUtils

import RxSwift

public class DirectiveSequencer: DirectiveSequenceable {
    private var handlingDirectives = [(directive: Downstream.Directive, blockingPolicy: BlockingPolicy)]()
    private var blockedDirectives = [(directive: Downstream.Directive, blockingPolicy: BlockingPolicy)]()
    
    private var delegates = DelegateSet<DirectiveSequencerDelegate>()
    @Atomic private var directiveHandleInfos = DirectiveHandleInfos()
    private var directiveCancelPolicies = [(dialogRequestId: String, policy: DirectiveCancelPolicy)]()
    private let directiveSequencerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.directive_sequencer", qos: .utility)
    private let disposeBag = DisposeBag()

    public init() { }
}

// MARK: - DirectiveSequenceable

public extension DirectiveSequencer {
    func add(delegate: DirectiveSequencerDelegate) {
        delegates.add(delegate)
    }
    
    func remove(delegate: DirectiveSequencerDelegate) {
        delegates.remove(delegate)
    }
    
    func add(directiveHandleInfos: DirectiveHandleInfos) {
        log.debug(directiveHandleInfos)
        _directiveHandleInfos.mutate { (infos) in
            infos.merge(directiveHandleInfos)
        }
    }
    
    func remove(directiveHandleInfos: DirectiveHandleInfos) {
        log.debug(directiveHandleInfos)
        _directiveHandleInfos.mutate { (infos) in
            directiveHandleInfos.keys.forEach { key in
                infos.removeValue(forKey: key)
            }
        }
    }
    
    func processDirective(_ directive: Downstream.Directive) {
        log.info(directive.header)
        
        directiveSequencerDispatchQueue.async { [weak self] in
            self?.prefetchDirective(directive)
        }
    }
    
    func processAttachment(_ attachment: Downstream.Attachment) {
        log.info(attachment.header)
        guard let handler = directiveHandleInfos[attachment.header.type] else {
            log.warning("No handler registered \(attachment.header)")
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
    func prefetchDirective(_ directive: Downstream.Directive) {
        guard let handler = directiveHandleInfos[directive.header.type] else {
            notifyDidComplete(directive: directive, result: .failed("No handler registered \(directive.header)"))
            return
        }
        guard isCancelledDirective(directive) == false else {
            notifyDidComplete(directive: directive, result: .canceled)
            return
        }
        
        // Directives should be prefetch sequentially.
        do {
            notifyWillPrefetch(directive: directive, handler: handler)
            log.info(directive.header)
            try handler.preFetch?(directive)
            
            directiveSequencerDispatchQueue.async { [weak self] in
                self?.handleDirective(directive)
            }
        } catch {
            notifyDidComplete(directive: directive, result: .failed("\(error)"))
        }
    }
    
    func handleDirective(_ directive: Downstream.Directive) {
        guard let handler = directiveHandleInfos[directive.header.type] else {
            log.warning("No handler registered \(directive.header)")
            notifyDidComplete(directive: directive, result: .failed("No handler registered \(directive.header)"))
            return
        }
        guard isCancelledDirective(directive) == false else {
            log.debug("Cancel directive \(directive.header)")
            handler.cancelDirective?(directive)
            notifyDidComplete(directive: directive, result: .canceled)
            return
        }
        guard handlingDirectives.contains(where: {
            $0.blockingPolicy.isBlocking == true &&
                $0.blockingPolicy.medium == handler.blockingPolicy.medium &&
                $0.directive.header.dialogRequestId == directive.header.dialogRequestId
        }) == false else {
            log.debug("Block directive \(directive.header)")
            blockedDirectives.append((directive: directive, blockingPolicy: handler.blockingPolicy))
            return
        }
        
        log.info(directive.header)
        notifyWillHandle(directive: directive, handler: handler)
        handlingDirectives.append((directive: directive, blockingPolicy: handler.blockingPolicy))
        handler.directiveHandler(directive) { [weak self ] result in
            self?.directiveSequencerDispatchQueue.async { [weak self] in
                guard let self = self else { return }

                if case .stopped(let directiveCancelPolicy) = result {
                    self.directiveCancelPolicies.append((dialogRequestId: directive.header.dialogRequestId, policy: directiveCancelPolicy))
                    if self.directiveCancelPolicies.count > 10 {
                        self.directiveCancelPolicies.remove(at: 0)
                    }
                }
                self.notifyDidComplete(directive: directive, result: result)
                self.handlingDirectives.removeAll { directive.header.messageId == $0.directive.header.messageId }

                // Block 된 Directive 다시시도.
                if handler.blockingPolicy.isBlocking {
                    let directives = self.blockedDirectives.filter { $0.blockingPolicy.medium == handler.blockingPolicy.medium }
                    self.blockedDirectives.removeAll { $0.blockingPolicy.medium == handler.blockingPolicy.medium }
                    directives.map { $0.directive }.forEach(self.handleDirective)
                }
            }
        }
    }
    
    func isCancelledDirective(_ directive: Downstream.Directive) -> Bool {
        directiveCancelPolicies.contains {
            let (dialogRequestId, policy) = $0
            guard directive.header.dialogRequestId == dialogRequestId else { return false }

            return policy.cancelAll || policy.cancelTargets.contains { $0 == directive.header.type }
        }
    }
    
    func notifyWillPrefetch(directive: Downstream.Directive, handler: DirectiveHandleInfo) {
        log.debug("\(directive.header)")
        delegates.notify {
            $0.directiveSequencerWillPrefetch(directive: directive, blockingPolicy: handler.blockingPolicy)
        }
    }
    
    func notifyWillHandle(directive: Downstream.Directive, handler: DirectiveHandleInfo) {
        log.debug("\(directive.header)")
        delegates.notify {
            $0.directiveSequencerWillHandle(directive: directive, blockingPolicy: handler.blockingPolicy)
        }
    }
    
    func notifyDidComplete(directive: Downstream.Directive, result: DirectiveHandleResult) {
        log.debug("\(directive.header): \(result)")
        delegates.notify {
            $0.directiveSequencerDidComplete(directive: directive, result: result)
        }
    }
}
