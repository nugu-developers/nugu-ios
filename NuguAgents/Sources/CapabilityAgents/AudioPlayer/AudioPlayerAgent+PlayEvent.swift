//
//  AudioPlayerAgent+PlayEvent.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 11/06/2019.
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

// MARK: - CapabilityEventAgentable

extension AudioPlayerAgent {
    public struct PlayEvent {
        let token: String
        let offsetInMilliseconds: Int
        let playServiceId: String
        let typeInfo: TypeInfo
        
        public enum TypeInfo {
            case playbackStarted
            case playbackFinished
            case playbackStopped
            case playbackFailed(error: Error)
            case progressReportDelayElapsed
            case progressReportIntervalElapsed
            case playbackPaused
            case playbackResumed
            case nextCommandIssued
            case previousCommandIssued
            case playCommandIssued
            case pauseCommandIssued
            case stopCommandIssued
            
            case requestResumeCommandIssued
            case requestNextCommandIssued
            case requestPreviousCommandIssued
            case requestPauseCommandIssued
            case requestStopCommandIssued
        }
    }
}

// MARK: - Eventable

extension AudioPlayerAgent.PlayEvent: Eventable {
    public var payload: [String: AnyHashable] {
        var eventPayload: [String: AnyHashable] = [
            "token": token,
            "offsetInMilliseconds": offsetInMilliseconds,
            "playServiceId": playServiceId
        ]
        
        switch typeInfo {
        case .playbackFailed(let error):
            let type: String
            switch error {
            case let mediaPlayerError as MediaPlayableError:
                switch mediaPlayerError {
                case .invalidURL:
                    type = "MEDIA_ERROR_INVALID_REQUEST"
                case .notPrepareSource:
                    type = "MEDIA_ERROR_INTERNAL_DEVICE_ERROR"
                default:
                    type = "MEDIA_ERROR_UNKNOWN"
                }
            default:
                type = "MEDIA_ERROR_INVALID_REQUEST"
            }
            
            eventPayload["error"] = [
                "type": type,
                "message": error.localizedDescription
            ]
        default:
            break
        }
        
        return eventPayload
    }
    
    public var name: String {
        switch typeInfo {
        case .playbackStarted:
            return "PlaybackStarted"
        case .playbackFinished:
            return "PlaybackFinished"
        case .playbackStopped:
            return "PlaybackStopped"
        case .playbackFailed:
            return "PlaybackFailed"
        case .progressReportDelayElapsed:
            return "ProgressReportDelayElapsed"
        case .progressReportIntervalElapsed:
            return "ProgressReportIntervalElapsed"
        case .playbackPaused:
            return "PlaybackPaused"
        case .playbackResumed:
            return "PlaybackResumed"
        case .nextCommandIssued:
            return "NextCommandIssued"
        case .previousCommandIssued:
            return "PreviousCommandIssued"
        case .playCommandIssued:
            return "PlayCommandIssued"
        case .pauseCommandIssued:
            return "PauseCommandIssued"
        case .stopCommandIssued:
            return "StopCommandIssued"
        case .requestResumeCommandIssued:
            return "RequestResumeCommandIssued"
        case .requestNextCommandIssued:
            return "RequestNextCommandIssued"
        case .requestPreviousCommandIssued:
            return "RequestPreviousCommandIssued"
        case .requestPauseCommandIssued:
            return "RequestPauseCommandIssued"
        case .requestStopCommandIssued:
            return "RequestStopCommandIssued"
        }
    }
}

// MARK: - Equatable

extension AudioPlayerAgent.PlayEvent.TypeInfo: Equatable {
    public static func == (lhs: AudioPlayerAgent.PlayEvent.TypeInfo, rhs: AudioPlayerAgent.PlayEvent.TypeInfo) -> Bool {
        switch (lhs, rhs) {
        case (.playbackFailed(let lhsParam), .playbackFailed(let rhsParam)):
            return lhsParam.localizedDescription == rhsParam.localizedDescription
        case (let lhs, let rhs):
            return lhs == rhs
        }
    }
}

extension AudioPlayerAgent.PlayEvent: Equatable {}
