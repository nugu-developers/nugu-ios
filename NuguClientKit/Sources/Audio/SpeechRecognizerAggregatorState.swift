//
//  SpeechRecognizerState.swift
//  NuguClientKit
//
//  Created by childc on 2021/08/11.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation
import NuguUtils

public enum SpeechRecognizerAggregatorState: Equatable {
    case idle
    case wakeupTriggering
    case wakeup
    case listening
    case recognizing
    case busy
    case cancelled
    case result(_ asr: String)
    case error(_ error: Error)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.wakeupTriggering, .wakeupTriggering),
             (.wakeup, .wakeup),
             (.listening, .listening),
             (.cancelled, .cancelled),
             (.result, .result),
             (.error, .error):
            return true
        default:
            return false
        }
    }
}
