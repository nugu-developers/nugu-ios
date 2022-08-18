//
//  DummyASRAgent.swift
//  NuguTests
//
//  Created by 신정섭님/A.출시 on 2022/08/17.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
//

import AVFAudio
import Foundation

import NuguAgents
import NuguCore

class DummyASRAgent: ASRAgentProtocol {
    var capabilityAgentProperty: CapabilityAgentProperty = .init(category: .automaticSpeechRecognition, version: "")
    var contextInfoProvider: ContextInfoProviderType = { _ in }
    
    var options: ASROptions = .init(endPointing: .client)
    
    var asrState: ASRState = .idle
    
    func putAudioBuffer(buffer: AVAudioPCMBuffer) {
        // Nothing to do.
    }
    
    func startRecognition(initiator: ASRInitiator, completion: ((StreamDataState) -> Void)?) -> String {
        // Nothiing to do.
        return ""
    }
    
    func stopRecognition() {
        // Nothing to do.
    }
    
    func stopSpeech() {
        // Nothing to do.
    }
}
