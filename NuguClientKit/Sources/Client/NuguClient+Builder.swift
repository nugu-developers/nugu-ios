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
        // core
        public let contextManager: ContextManageable
        public let focusManager: FocusManageable
        public let directiveSequencer: DirectiveSequenceable
        public let streamDataRouter: StreamDataRoutable
        public let playSyncManager: PlaySyncManageable
        public let dialogAttributeStore: DialogAttributeStoreable
        public let sessionManager: SessionManageable
        public let interactionControlManager: InteractionControlManageable
        public let systemAgent: SystemAgentProtocol
        
        // default agents
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
            dialogAttributeStore: dialogAttributeStore
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
        
        public lazy var soundAgent: SoundAgentProtocol = SoundAgent(
            focusManager: focusManager,
            upstreamDataSender: streamDataRouter,
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
        
        // additional agents
        public lazy var displayAgent: DisplayAgentProtocol = DisplayAgent(
            upstreamDataSender: streamDataRouter,
            playSyncManager: playSyncManager,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer,
            sessionManager: sessionManager,
            interactionControlManager: interactionControlManager
        )
        
        public lazy var extensionAgent: ExtensionAgentProtocol = ExtensionAgent(
            upstreamDataSender: streamDataRouter,
            contextManager: contextManager,
            directiveSequencer: directiveSequencer
        )
        
        public lazy var locationAgent: LocationAgentProtocol = LocationAgent(contextManager: contextManager)
        
        public lazy var phoneCallAgent: PhoneCallAgentProtocol = PhoneCallAgent(
            directiveSequencer: directiveSequencer,
            contextManager: contextManager,
            upstreamDataSender: streamDataRouter,
            interactionControlManager: interactionControlManager
        )
        
        public lazy var mediaPlayerAgent: MediaPlayerAgentProtocol = MediaPlayerAgent(
            directiveSequencer: directiveSequencer,
            contextManager: contextManager,
            upstreamDataSender: streamDataRouter
        )
        
        // supports
        /**
         AudioSessionManager.
         
         - note: If you want to control AVAudioSession, Set this property to nil.
         Then NuguClientDelegate method will be called when the AVAudioSession is required.
         */
        public lazy var audioSessionManager: AudioSessionManageable? = AudioSessionManager(audioPlayerAgent: audioPlayerAgent)
        public lazy var keywordDetector: KeywordDetector = KeywordDetector(contextManager: contextManager)
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
                mediaPlayerAgent: mediaPlayerAgent,
                soundAgent: soundAgent,
                sessionAgent: sessionAgent,
                chipsAgent: chipsAgent,
                utilityAgent: utilityAgent,
                displayAgent: displayAgent,
                extensionAgent: extensionAgent,
                locationAgent: locationAgent,
                phoneCallAgent: phoneCallAgent,
                audioSessionManager: audioSessionManager,
                keywordDetector: keywordDetector,
                speechRecognizerAggregator: speechRecognizerAggregator
            )
        }
    }
}
