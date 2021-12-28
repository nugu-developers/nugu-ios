//
//  SpeechRecognizerState.swift
//  NuguClientKit
//
//  Created by childc on 2021/08/11.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation

import NuguUtils
import NuguAgents

public enum SpeechRecognizerAggregatorState: Equatable {
    case idle
    case wakeupTriggering
    case wakeup(initiator: ASRInitiator)
    case listening
    case recognizing
    case busy
    case cancelled
    case result(_ result: Result)
    case error(_ error: Error)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.wakeupTriggering, .wakeupTriggering),
             (.wakeup, .wakeup),
             (.listening, .listening),
             (.recognizing, .recognizing),
             (.busy, .busy),
             (.cancelled, .cancelled):
            return true
        case (.error, .error):
            return false
        case (.result(let lhsResult), .result(let rhsResult)):
            guard lhsResult.type == rhsResult.type else {
                return false
            }
            return (lhsResult.value) == (rhsResult.value)
        default:
            return false
        }
    }
    
    public struct Result {
        public let type: ResultType
        public let value: String
        
        public enum ResultType {
            case partial
            case complete
        }
    }
}

// MARK: - SpeechRecognizerAggregatorState transform

extension SpeechRecognizerAggregatorState {
    init?(_ asrState: ASRState) {
        switch asrState {
        case .idle:
            self = .idle
        case .listening:
            self = .listening
        case .recognizing:
            self = .recognizing
        case .busy:
            self = .busy
        default:
            return nil
        }
    }
    
    init?(_ asrResult: ASRResult) {
        switch asrResult {
        case .none:
            self = .result(Result(type: .complete, value: ""))
        case .partial(let text, _):
            self = .result(Result(type: .partial, value: text))
        case .complete(let text, _):
            self = .result(Result(type: .complete, value: text))
        case .cancel, .cancelExpectSpeech:
            self = .cancelled
        case .error(let error, _):
            self = .error(error)
        }
    }
    
    init?(_ kwdState: KeywordDetectorState) {
        switch kwdState {
        case .active:
            self = .wakeupTriggering
        default:
            return nil
        }
    }
}
