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
    
    @Atomic private var directiveHandleInfos = DirectiveHandleInfos()
    private var directiveCancelPolicies = [(dialogRequestId: String, policy: DirectiveCancelPolicy)]()
    private let directiveSequencerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.directive_sequencer", qos: .utility)
    private let disposeBag = DisposeBag()
    
    public init() {}
}

// MARK: - DirectiveSequenceable

public extension DirectiveSequencer {
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
    
    func cancelDirective(dialogRequestId: String) {
        directiveSequencerDispatchQueue.async { [weak self] in
            log.debug(dialogRequestId)
            self?.directiveCancelPolicies.append((dialogRequestId: dialogRequestId, policy: .cancelAll))
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
        guard shouldBlocked(blockingPolicy: handler.blockingPolicy, directive: directive) == false else {
            log.debug("Block directive \(directive.header)")
            blockedDirectives.append((directive: directive, blockingPolicy: handler.blockingPolicy))
            return
        }
        
        log.info(directive.header)
        blockedDirectives.removeAll { $0.directive.header.messageId == directive.header.messageId }
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
                self.enqueueBlockedDirectivies()
            }
        }
    }
    
    func shouldBlocked(blockingPolicy: BlockingPolicy, directive: Downstream.Directive) -> Bool {
        let directives = (handlingDirectives + blockedDirectives)
            .filter { $0.directive.header.dialogRequestId == directive.header.dialogRequestId }
        let targetDirectiveCount = directives.firstIndex {
            $0.directive.header.messageId == directive.header.messageId
        } ?? directives.count
        
        if targetDirectiveCount == 0 {
            return false
        }
        
        return directives[0..<targetDirectiveCount]
            .contains(where: {
                if blockingPolicy.medium == .any {
                    return true
                }
                if $0.blockingPolicy.isBlocking == true {
                    if $0.blockingPolicy.medium == blockingPolicy.medium || $0.blockingPolicy.medium == .any {
                        return true
                    }
                }
                
                return false
            })
    }
    
    func enqueueBlockedDirectivies() {
        blockedDirectives
            .filter { shouldBlocked(blockingPolicy: $0.blockingPolicy, directive: $0.directive) == false }
            .forEach { handleDirective($0.directive) }
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
        post(NuguCoreNotification.DirectiveSquencer.Prefetch(directive: directive, blockingPolicy: handler.blockingPolicy))
    }
    
    func notifyWillHandle(directive: Downstream.Directive, handler: DirectiveHandleInfo) {
        log.debug("\(directive.header)")
        post(NuguCoreNotification.DirectiveSquencer.Handle(directive: directive, blockingPolicy: handler.blockingPolicy))
    }
    
    func notifyDidComplete(directive: Downstream.Directive, result: DirectiveHandleResult) {
        log.debug("\(directive.header): \(result)")
        post(NuguCoreNotification.DirectiveSquencer.Complete(directive: directive, result: result))
    }
}

// MARK: - Observers

extension Notification.Name {
    static let directiveSequencerWillPrefetch = Notification.Name("com.sktelecom.romaine.notification.name.directive_sequencer_will_prefetch")
    static let directiveSequencerWillHandle = Notification.Name("com.sktelecom.romaine.notification.name.directive_sequencer_will_handle")
    static let directiveSequencerDidComplete = Notification.Name("com.sktelecom.romaine.notification.name.directive_sequencer_did_complete")
}

public extension NuguCoreNotification {
    enum DirectiveSquencer {
        public struct Prefetch: TypedNotification {
            public static var name: Notification.Name = .directiveSequencerWillPrefetch
            public let directive: Downstream.Directive
            public let blockingPolicy: BlockingPolicy
            
            public static func make(from: [String: Any]) -> Prefetch? {
                guard let directive = from["directive"] as? Downstream.Directive,
                      let blockingPolicy = from["blockingPolicy"] as? BlockingPolicy else { return nil }

                return Prefetch(directive: directive, blockingPolicy: blockingPolicy)
            }
        }
        
        public struct Handle: TypedNotification {
            public static var name: Notification.Name = .directiveSequencerWillHandle
            public let directive: Downstream.Directive
            public let blockingPolicy: BlockingPolicy
            
            public static func make(from: [String: Any]) -> Handle? {
                guard let directive = from["directive"] as? Downstream.Directive,
                      let blockingPolicy = from["blockingPolicy"] as? BlockingPolicy else { return nil }

                return Handle(directive: directive, blockingPolicy: blockingPolicy)
            }
        }
        
        public struct Complete: TypedNotification {
            public static var name: Notification.Name = .directiveSequencerDidComplete
            public let directive: Downstream.Directive
            public let result: DirectiveHandleResult
            
            public static func make(from: [String: Any]) -> Complete? {
                guard let directive = from["directive"] as? Downstream.Directive,
                      let result = from["result"] as? DirectiveHandleResult else { return nil }

                return Complete(directive: directive, result: result)
            }
        }
    }
}
