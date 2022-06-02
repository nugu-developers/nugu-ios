//
//  NuguClient+Builder.swift
//  NuguClientKit
//
//  Created by childc on 2021/02/03.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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
import NuguAgents

public extension NuguClient {
    class Builder {
        // Core
        public let contextManager: ContextManageable
        public let focusManager: FocusManageable
        public let directiveSequencer: DirectiveSequenceable
        public let streamDataRouter: StreamDataRoutable
        public let playSyncManager: PlaySyncManageable
        public let dialogAttributeStore: DialogAttributeStoreable
        public let sessionManager: SessionManageable
        public let interactionControlManager: InteractionControlManageable
        public let systemAgent: SystemAgentProtocol
        
        // Default Agents
        public lazy var asrAgent: ASRAgentProtocol = ASRAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer,
            dialogAttributeStore: dialogAttributeStore,
            sessionManager: sessionManager,
            playSyncManager: playSyncManager,
            interactionControlManager: interactionControlManager
        )
        
        public lazy var ttsAgent: TTSAgentProtocol = TTSAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
            playSyncManager: playSyncManager,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        public lazy var textAgent: TextAgentProtocol = TextAgent(
            contextManager: contextManager,
            upstreamDataSender: streamDataRouter,
            directiveSequencer: directiveSequencer,
            dialogAttributeStore: dialogAttributeStore,
            interactionControlManager: interactionControlManager
        )
        
        public lazy var chipsAgent: ChipsAgentProtocol = ChipsAgent(
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        public lazy var audioPlayerAgent: AudioPlayerAgentProtocol = AudioPlayerAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
            playSyncManager: playSyncManager,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        public lazy var sessionAgent: SessionAgentProtocol = SessionAgent(
            contextManager: contextManager,
            directiveSequencer: directiveSequencer,
            sessionManager: sessionManager
        )
        
        public lazy var utilityAgent: UtilityAgentProtocol = UtilityAgent(
            directiveSequencer: directiveSequencer,
            contextManager: contextManager
        )
        
        public lazy var routineAgent: RoutineAgentProtocol = RoutineAgent(
            upstreamDataSender: streamDataRouter,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer,
            streamDataRouter: streamDataRouter,
            textAgent: textAgent,
            asrAgent: asrAgent
        )
        
        public lazy var nudgeAgent: NudgeAgentProtocol = NudgeAgent(
            directiveSequencer: directiveSequencer,
            contextManager: contextManager,
            playSyncManager: playSyncManager
        )
        
        // Additional Agents
        /**
         Play some special sound on the special occasion
         */
        public var soundAgent: SoundAgentProtocol?
        
        /**
         Make a phone call
         */
        public var phoneCallAgent: PhoneCallAgentProtocol?
        
        /**
         Send a text message (SMS)
         */
        public var messageAgent: MessageAgentProtocol?
        
        /**
         Play your own audio contents
         
         - seeAlso: `AudioPlayerAgent`
         */
        public var mediaPlayerAgent: MediaPlayerAgentProtocol?
        
        /**
         Receive custom directives you made.
         */
        public var extensionAgent: ExtensionAgentProtocol?
        
        /**
         Send a location information
         */
        public var locationAgent: LocationAgentProtocol?
        
        /**
         Handles directives for system permission.
         */
        public var permissionAgent: PermissionAgentProtocol?
        
        /**
         Set alerts
         */
        public var alertsAgent: AlertsAgentProtocol?
        
        /**
         Show Graphical User Interface
         */
        public var displayAgent: DisplayAgentProtocol?
        
        // Supports
        /**
         AudioSessionManager.
         
         - note: If you want to control AVAudioSession yourself, Set this property to nil.
         Then NuguClientDelegate method will be called when the AVAudioSession is required.
         */
        public lazy var audioSessionManager: AudioSessionManageable? = AudioSessionManager(audioPlayerAgent: audioPlayerAgent)
        
        /**
         Keyword Detector.
         
         Detects an "aria" statement.
         */
        public lazy var keywordDetector: KeywordDetector = KeywordDetector(contextManager: contextManager)
        
        /**
         It manages `KeywordDetector`, `ASRAgent`, `Mic`
         
         So you don't have to care about the ASR setting.
         */
        public lazy var speechRecognizerAggregator: SpeechRecognizerAggregatable = SpeechRecognizerAggregator(
            keywordDetector: keywordDetector,
            asrAgent: asrAgent
        )
        
        public init() {
            // core
            contextManager = ContextManager()
            directiveSequencer = DirectiveSequencer()
            focusManager = FocusManager()
            streamDataRouter = StreamDataRouter(directiveSequencer: directiveSequencer)
            playSyncManager = PlaySyncManager(contextManager: contextManager)
            dialogAttributeStore = DialogAttributeStore()
            sessionManager = SessionManager()
            interactionControlManager = InteractionControlManager()
            systemAgent = SystemAgent(
                contextManager: contextManager,
                streamDataRouter: streamDataRouter,
                directiveSequencer: directiveSequencer
            )
        }

        /**
         Set the instance as a delegator.
         
         - note: You can set multiple delegates that this instance conforms at once.
         */
        @discardableResult public func setDelegate<Delegate>(_ delegate: Delegate) -> Self {
            // Because `delegate` instance can be a Multi-Delegator, We don't use switch syntax.
            if delegate is TextAgentDelegate {
                textAgent.delegate = delegate as? TextAgentDelegate
            }
            
            if delegate is PhoneCallAgentDelegate {
                phoneCallAgent = PhoneCallAgent(
                    directiveSequencer: directiveSequencer,
                    contextManager: contextManager,
                    upstreamDataSender: streamDataRouter,
                    interactionControlManager: interactionControlManager
                )
                phoneCallAgent?.delegate = delegate as? PhoneCallAgentDelegate
            }
            
            if delegate is MessageAgentDelegate {
                messageAgent = MessageAgent(
                    directiveSequencer: directiveSequencer,
                    contextManager: contextManager,
                    upstreamDataSender: streamDataRouter,
                    interactionControlManager: interactionControlManager
                )
                messageAgent?.delegate = delegate as? MessageAgentDelegate
            }
            
            if delegate is MediaPlayerAgentDelegate {
                mediaPlayerAgent = MediaPlayerAgent(
                    directiveSequencer: directiveSequencer,
                    contextManager: contextManager,
                    upstreamDataSender: streamDataRouter
                )
                mediaPlayerAgent?.delegate = delegate as? MediaPlayerAgentDelegate
            }
            
            if delegate is ExtensionAgentDelegate {
                extensionAgent = ExtensionAgent(
                    upstreamDataSender: streamDataRouter,
                    contextManager: contextManager,
                    directiveSequencer: directiveSequencer
                )
                extensionAgent?.delegate = delegate as? ExtensionAgentDelegate
            }
            
            if delegate is LocationAgentDelegate {
                locationAgent = LocationAgent(contextManager: contextManager)
                locationAgent?.delegate = delegate as? LocationAgentDelegate
            }
            
            if delegate is PermissionAgentDelegate {
                permissionAgent = PermissionAgent(
                    contextManager: contextManager,
                    directiveSequencer: directiveSequencer
                )
                permissionAgent?.delegate = delegate as? PermissionAgentDelegate
            }
            
            if delegate is AlertsAgentDelegate {
                alertsAgent = AlertsAgent(
                    directiveSequencer: directiveSequencer,
                    contextManager: contextManager,
                    upstreamDataSender: streamDataRouter
                )
                alertsAgent?.delegate = delegate as? AlertsAgentDelegate
            }
            
            return self
        }
        
        /**
         Set the instance as a data source.
         
         - note: You can set multiple data sources that this instance conforms at once.
         */
        @discardableResult public func setDataSource<DataSource>(_ dataSource: DataSource) -> Self {
            // Because `dataSource` instance can be a Multi-Source, We don't use switch statement.
            if dataSource is SoundAgentDataSource {
                soundAgent = SoundAgent(
                    focusManager: focusManager,
                    upstreamDataSender: streamDataRouter,
                    contextManager: contextManager,
                    directiveSequencer: directiveSequencer
                )
                soundAgent?.dataSource = dataSource as? SoundAgentDataSource
            }
            
            return self
        }
        
        /**
         Instantiate the NuguClient.
         
         The core components and default agents will be initiated automatically.
         But, Additional agents won't be initiated before you access them.
         */
        public func build() -> NuguClient {
            return NuguClient(
                contextManager: contextManager,
                focusManager: focusManager,
                streamDataRouter: streamDataRouter,
                directiveSequencer: directiveSequencer,
                playSyncManager: playSyncManager,
                dialogAttributeStore: dialogAttributeStore,
                sessionManager: sessionManager,
                systemAgent: systemAgent,
                interactionControlManager: interactionControlManager,
                asrAgent: asrAgent,
                ttsAgent: ttsAgent,
                textAgent: textAgent,
                audioPlayerAgent: audioPlayerAgent,
                sessionAgent: sessionAgent,
                chipsAgent: chipsAgent,
                utilityAgent: utilityAgent,
                routineAgent: routineAgent,
                audioSessionManager: audioSessionManager,
                keywordDetector: keywordDetector,
                speechRecognizerAggregator: speechRecognizerAggregator,
                mediaPlayerAgent: mediaPlayerAgent,
                extensionAgent: extensionAgent,
                phoneCallAgent: phoneCallAgent,
                messageAgent: messageAgent,
                soundAgent: soundAgent,
                displayAgent: displayAgent,
                locationAgent: locationAgent,
                permissionAgent: permissionAgent,
                alertsAgent: alertsAgent,
                nudgeAgent: nudgeAgent
            )
        }
    }
}
