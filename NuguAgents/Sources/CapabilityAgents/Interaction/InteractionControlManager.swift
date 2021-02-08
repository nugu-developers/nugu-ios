//
//  InteractionControlManager.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/08/07.
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
import NuguCore

import RxSwift

public class InteractionControlManager: InteractionControlManageable {
    private let interactionDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.interaction_control", qos: .userInitiated)
    private lazy var interactioniScheduler = SerialDispatchQueueScheduler(
        queue: interactionDispatchQueue,
        internalSerialQueueName: "com.sktelecom.romaine.interaction_control"
    )
    
    private var interactionControls = Set<CapabilityAgentCategory>()
    private var timeoutTimers = [String: Disposable]()
    
    public init() {}
}

// MARK: - InteractionControlManageable

public extension InteractionControlManager {
    func start(mode: InteractionControl.Mode, category: CapabilityAgentCategory) {
        log.debug(category)
        interactionDispatchQueue.async { [weak self] in
            guard let self = self, mode == .multiTurn else { return }
            
            self.addTimer(category: category)
            self.interactionControls.insert(category)
            if self.interactionControls.count == 1 {
                self.post(NuguAgentNotification.InteractionControl.MultiTurn(multiTurn: true))
            }
        }
    }
    
    func finish(mode: InteractionControl.Mode, category: CapabilityAgentCategory) {
        log.debug(category)
        interactionDispatchQueue.async { [weak self] in
            guard let self = self, mode == .multiTurn else { return }
            
            self.removeTimer(category: category)
            self.interactionControls.remove(category)
            if self.interactionControls.isEmpty {
                self.post(NuguAgentNotification.InteractionControl.MultiTurn(multiTurn: false))
            }
        }
    }
}

private extension InteractionControlManager {
    func addTimer(category: CapabilityAgentCategory) {
        log.debug(category)
        timeoutTimers[category.name] = Single<Int>.timer(InteractionControlConst.timeout, scheduler: interactioniScheduler)
            .subscribe(onSuccess: { [weak self] _ in
                guard let self = self else { return }
                
                log.debug("Timer fired. \(category)")
                self.interactionControls.remove(category)
                if self.interactionControls.isEmpty {
                    self.post(NuguAgentNotification.InteractionControl.MultiTurn(multiTurn: false))
                }
            })
    }
    
    func removeTimer(category: CapabilityAgentCategory) {
        log.debug(category)
        timeoutTimers[category.name]?.dispose()
        timeoutTimers[category.name] = nil
    }
}

// MARK: - Observer

extension Notification.Name {
    static let interactionControlDidChange = Notification.Name("com.sktelecom.romain.notification.name.interaction_control_did_change")
}

public extension NuguAgentNotification {
    enum InteractionControl {
        public struct MultiTurn: TypedNotification {
            public static let name: Notification.Name = .interactionControlDidChange
            public let multiTurn: Bool
            
            public static func make(from: [String: Any]) -> MultiTurn? {
                guard let multiTurn = from["multiTurn"] as? Bool else { return nil }
                
                return MultiTurn(multiTurn: multiTurn)
            }
        }
    }
}
