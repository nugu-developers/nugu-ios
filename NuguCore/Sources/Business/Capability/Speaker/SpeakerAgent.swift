//
//  SpeakerAgent.swift
//  NuguCore
//
//  Created by yonghoonKwon on 23/05/2019.
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

final public class SpeakerAgent: SpeakerAgentProtocol, CapabilityDirectiveAgentable, CapabilityEventAgentable {
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .speaker, version: "1.0")
    
    private let speakerDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.speaker_agent", qos: .userInitiated)
    
    public let upstreamDataSender: UpstreamDataSendable
    
    public weak var delegate: SpeakerAgentDelegate?
    private let speakerVolumeDelegates = DelegateSet<SpeakerVolumeDelegate>()
    
    public init(upstreamDataSender: UpstreamDataSendable) {
        log.info("")
        
        self.upstreamDataSender = upstreamDataSender
    }
    
    deinit {
        log.info("")
    }
}

// MARK: - SpeakerAgentProtocol

public extension SpeakerAgent {
    func add(speakerVolumeDelegate: SpeakerVolumeDelegate) {
        speakerVolumeDelegates.add(speakerVolumeDelegate)
    }
    
    func remove(speakerVolumeDelegate: SpeakerVolumeDelegate) {
        speakerVolumeDelegates.remove(speakerVolumeDelegate)
    }
    
    func set(type: SpeakerVolumeType, muted: Bool) {
        let controllers = self.speakerVolumeDelegates.allObjects
        let succeeded = controllers.filter { $0.speakerVolumeType() == type }
            .allSatisfy { $0.speakerVolumeShouldChange(muted: muted) }
        
        if succeeded {
            self.delegate?.speakerAgentDidChange(type: type, muted: muted)
        }
    }
}

// MARK: - HandleDirectiveDelegate

extension SpeakerAgent: HandleDirectiveDelegate {
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
            case .setMute:
                return setMute(directive: directive)
            }
        })
        
        completionHandler(result)
    }
}

// MARK: - ContextInfoDelegate

extension SpeakerAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        let payload: [String: Any] = [
            "version": capabilityAgentProperty.version,
            "volumes": controllerVolumes.values
        ]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload)
    }
}

// MARK: - Private(Directive)

private extension SpeakerAgent {
    func setMute(directive: Downstream.Directive) -> Result<Void, Error> {
        return Result<Void, Error> { [weak self] in
            guard let data = directive.payload.data(using: .utf8) else {
                throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
            }
            
            let speakerMuteInfo = try JSONDecoder().decode(SpeakerMuteInfo.self, from: data)
            
            self?.speakerDispatchQueue.async { [weak self] in
                guard let self = self else { return }
                
                let controllers = self.speakerVolumeDelegates.allObjects
                let results = speakerMuteInfo.volumes.map({ (volume) -> Bool in
                    let result = controllers.filter { $0.speakerVolumeType() == volume.name }
                        .allSatisfy { $0.speakerVolumeShouldChange(muted: volume.mute) }
                    if result {
                        self.delegate?.speakerAgentDidChange(type: volume.name, muted: volume.mute)
                    }
                    return result
                })

                let succeeded = results.allSatisfy { $0 }
                let typeInfo: SpeakerAgent.Event.TypeInfo = succeeded ? .setMuteSucceeded : .setMuteFailed
                
                self.sendEvent(
                    Event(typeInfo: typeInfo, volumes: self.controllerVolumes, playServiceId: speakerMuteInfo.playServiceId),
                    dialogRequestId: TimeUUID().hexString
                )
            }
        }
    }
}

// MARK: - Private

private extension SpeakerAgent {
    var controllerVolumes: [SpeakerMuteInfo.Volume] {
        let controllers = speakerVolumeDelegates.allObjects
        return SpeakerVolumeType.allCases
            .filter({ (type) -> Bool in
                return controllers.contains { $0.speakerVolumeType() == type }
            })
            .map { (type) -> SpeakerMuteInfo.Volume in
                let isMuted = controllers.contains { $0.speakerVolumeType() == type && $0.speakerVolumeIsMuted() }
                return SpeakerMuteInfo.Volume(name: type, mute: isMuted)
        }
    }
}
