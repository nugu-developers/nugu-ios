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
    public let authorizationManager = AuthorizationManager.shared
    /// <#Description#>
    public let focusManager: FocusManageable = FocusManager()
    /// <#Description#>
    public let networkManager: NetworkManageable = NetworkManager()
    /// <#Description#>
    public let dialogStateAggregator: DialogStateAggregatable = DialogStateAggregator()
    /// <#Description#>
    public let contextManager: ContextManageable = ContextManager()
    /// <#Description#>
    public let playSyncManager: PlaySyncManageable = PlaySyncManager()
    /// <#Description#>
    public lazy var directiveSequencer: DirectiveSequenceable = DirectiveSequencer(messageSender: networkManager)
    /// <#Description#>
    let mediaPlayerFactory = MediaPlayerFactory()

    // MARK: - Audio Related

    /// <#Description#>
    public let inputProvider: AudioProvidable?
    /// <#Description#>
    public let sharedAudioStream: AudioStreamable?
    /// <#Description#>
    public let endPointDetector: EndPointDetectable?
    /// <#Description#>
    public var wakeUpDetector: WakeUpDetectable? {
        didSet {
            setupWakeUpDetectorDependency()
        }
    }
    
    // MARK: - Capability Agents
    
    /// <#Description#>
    public let asrAgent: ASRAgentProtocol?
    /// <#Description#>
    public let ttsAgent: TTSAgentProtocol?
    /// <#Description#>
    public let audioPlayerAgent: AudioPlayerAgentProtocol?
    /// <#Description#>
    public let displayAgent: DisplayAgentProtocol?
    /// <#Description#>
    public let speakerAgent: SpeakerAgentProtocol?
    /// <#Description#>
    public let textAgent: TextAgentProtocol?
    /// <#Description#>
    public let extensionAgent: ExtensionAgentProtocol?
    /// <#Description#>
    public let locationAgent: LocationAgentProtocol?
    /// <#Description#>
    public let systemAgent: SystemAgentProtocol

    init(inputProvider: AudioProvidable?,
         sharedAudioStream: AudioStreamable?,
         endPointDetector: EndPointDetectable?,
         wakeUpDetector: WakeUpDetectable?,
         asrAgent: ASRAgentProtocol?,
         ttsAgent: TTSAgentProtocol?,
         audioPlayerAgent: AudioPlayerAgentProtocol?,
         displayAgent: DisplayAgentProtocol?,
         speakerAgent: SpeakerAgentProtocol?,
         textAgent: TextAgentProtocol?,
         extensionAgent: ExtensionAgentProtocol?,
         locationAgent: LocationAgentProtocol?) {
        log.info("with NuguApp")
        
        self.inputProvider = inputProvider
        self.sharedAudioStream = sharedAudioStream
        self.endPointDetector = endPointDetector
        self.wakeUpDetector = wakeUpDetector
        self.asrAgent = asrAgent
        self.ttsAgent = ttsAgent
        self.audioPlayerAgent = audioPlayerAgent
        self.displayAgent = displayAgent
        self.speakerAgent = speakerAgent
        self.textAgent = textAgent
        self.extensionAgent = extensionAgent
        self.locationAgent = locationAgent
        self.systemAgent = SystemAgent()
        
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
        if let sharedAudioStream = sharedAudioStream,
            inputProvider?.isRunning == false {
            try? inputProvider?.start(streamWriter: sharedAudioStream.makeAudioStreamWriter())
            
            log.debug("input provider is started.")
        }
    }
    
    public func audioStreamDidStop() {
        if inputProvider?.isRunning == true {
            inputProvider?.stop()
            
            log.debug("input provider is stopped.")
        }
    }
}
