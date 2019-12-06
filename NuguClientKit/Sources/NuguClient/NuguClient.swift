//
//  NuguClient.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 09/04/2019.
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

import NuguCore
import NuguInterface

import NattyLog

let log = NuguClient.natty

/// <#Description#>
public class NuguClient {
    // Static
    fileprivate static let natty: NattyLog.Natty = NattyLog.Natty(by: nattyConfiguration)
    private static var nattyConfiguration: NattyLog.NattyConfiguration {
        #if DEBUG
        return NattyLog.NattyConfiguration(
            minLogLevel: .debug,
            maxDescriptionLevel: .error,
            showPersona: true,
            prefix: "NuguClient")
        #else
        return NattyLog.NattyConfiguration(
            minLogLevel: .warning,
            maxDescriptionLevel: .warning,
            showPersona: true,
            prefix: "NuguClient")
        #endif
    }
    
    /// <#Description#>
    public static let `default` = NuguClient.Builder().build()
    
    /// <#Description#>
    public static var logEnabled: Bool {
        set {
            switch newValue {
            case true:
                #if DEBUG
                natty.configuration.minLogLevel = .debug
                #else
                natty.configuration.minLogLevel = .warning
                #endif
            case false:
                natty.configuration.minLogLevel = .nothing
            }
        } get {
            switch nattyConfiguration.minLogLevel {
            case .nothing:
                return false
            default:
                return true
            }
        }
    }

    // MARK: - Mandatory
    
    /// <#Description#>
    public let authorizationManager: AuthorizationManager
    /// <#Description#>
    public let focusManager: FocusManageable
    /// <#Description#>
    public let networkManager: NetworkManageable
    /// <#Description#>
    public let dialogStateAggregator: DialogStateAggregatable
    /// <#Description#>
    public let contextManager: ContextManageable
    /// <#Description#>
    public let playSyncManager: PlaySyncManageable
    /// <#Description#>
    public let directiveSequencer: DirectiveSequenceable
    /// <#Description#>
    public let downStreamDataInterpreter: DownStreamDataInterpretable
    /// <#Description#>
    public let mediaPlayerFactory: MediaPlayableFactory
    
    // MARK: - Related Audio

    /// <#Description#>
    public let inputProvider: AudioProvidable?
    /// <#Description#>
    public let sharedAudioStream: AudioStreamable?
    /// <#Description#>
    public let endPointDetector: EndPointDetectable?
    /// <#Description#>
    public let wakeUpDetector: KeywordDetector?
    
    // MARK: - Capability Agents
    
    /// <#Description#>
    public let systemAgent: SystemAgentProtocol
    /// <#Description#>
    public let asrAgent: ASRAgentProtocol?
    /// <#Description#>
    public let ttsAgent: TTSAgentProtocol?
    /// <#Description#>
    public let audioPlayerAgent: AudioPlayerAgentProtocol?
    /// <#Description#>
    public let displayAgent: DisplayAgentProtocol?
    /// <#Description#>
    public let textAgent: TextAgentProtocol?
    /// <#Description#>
    public let extensionAgent: ExtensionAgentProtocol?
    /// <#Description#>
    public let locationAgent: LocationAgentProtocol?
    
    private let inputControlQueue = DispatchQueue(label: "com.sktelecom.romaine.input_control_queue")
    private var inputControlWorkItem: DispatchWorkItem?

    init(
        authorizationManager: AuthorizationManager,
        focusManager: FocusManageable,
        networkManager: NetworkManageable,
        dialogStateAggregator: DialogStateAggregatable,
        contextManager: ContextManageable,
        playSyncManager: PlaySyncManageable,
        directiveSequencer: DirectiveSequenceable,
        downStreamDataInterpreter: DownStreamDataInterpretable,
        mediaPlayerFactory: MediaPlayableFactory,
        inputProvider: AudioProvidable?,
        sharedAudioStream: AudioStreamable?,
        endPointDetector: EndPointDetectable?,
        wakeUpDetector: KeywordDetector?,
        systemAgent: SystemAgentProtocol,
        asrAgent: ASRAgentProtocol?,
        ttsAgent: TTSAgentProtocol?,
        audioPlayerAgent: AudioPlayerAgentProtocol?,
        displayAgent: DisplayAgentProtocol?,
        textAgent: TextAgentProtocol?,
        extensionAgent: ExtensionAgentProtocol?,
        locationAgent: LocationAgentProtocol?
    ) {
        log.info("with NuguApp")
        
        self.authorizationManager = authorizationManager
        self.focusManager = focusManager
        self.networkManager = networkManager
        self.dialogStateAggregator = dialogStateAggregator
        self.contextManager = contextManager
        self.playSyncManager = playSyncManager
        self.directiveSequencer = directiveSequencer
        self.downStreamDataInterpreter = downStreamDataInterpreter
        self.mediaPlayerFactory = mediaPlayerFactory
        self.inputProvider = inputProvider
        self.sharedAudioStream = sharedAudioStream
        self.endPointDetector = endPointDetector
        self.wakeUpDetector = wakeUpDetector
        self.systemAgent = systemAgent
        self.asrAgent = asrAgent
        self.ttsAgent = ttsAgent
        self.audioPlayerAgent = audioPlayerAgent
        self.displayAgent = displayAgent
        self.textAgent = textAgent
        self.extensionAgent = extensionAgent
        self.locationAgent = locationAgent
        
        setupDependencies()
    }
}

// MARK: - Authorization

public extension NuguClient {
    /// <#Description#>
    var accessToken: String? {
        get {
            return authorizationManager.authorizationPayload?.accessToken
        } set {
            guard let newAccessToken = newValue else {
                authorizationManager.authorizationPayload = nil
                return
            }
            
            authorizationManager.authorizationPayload = AuthorizationPayload(accessToken: newAccessToken)
        }
    }
}

// MARK: - AudioStreamDelegate

extension NuguClient: AudioStreamDelegate {
    public func audioStreamWillStart() {
        inputControlWorkItem?.cancel()
        inputControlQueue.async { [weak self] in
            guard let sharedAudioStream = self?.sharedAudioStream,
                self?.inputProvider?.isRunning == false else {
                    log.debug("input provider is already started.")
                    return
            }
            
            do {
                try self?.inputProvider?.start(streamWriter: sharedAudioStream.makeAudioStreamWriter())
                log.debug("input provider is started.")
            } catch {
                log.debug("input provider failed to start: \(error)")
            }
        }
    }
    
    public func audioStreamDidStop() {
        inputControlWorkItem?.cancel()
        inputControlWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            guard self.inputControlWorkItem?.isCancelled == false else {
                log.debug("Stopping input provider is cancelled")
                return
            }
            
            guard self.inputProvider?.isRunning == true else {
                log.debug("input provider is not running")
                return
            }
            
            self.inputProvider?.stop()
            log.debug("input provider is stopped.")
            
        }
        
        inputControlQueue.asyncAfter(deadline: .now() + 3, execute: inputControlWorkItem!)
    }
}
