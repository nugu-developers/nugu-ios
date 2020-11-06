//
//  MediaPlayerAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/10.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

extension MediaPlayerAgent {
    struct Event {
        let typeInfo: TypeInfo
        let playServiceId: String
        let token: String?
        let referrerDialogRequestId: String?
        
        enum TypeInfo {
            case playSucceeded(message: String?)
            case playSuspended(song: MediaPlayerAgentSong?, playlist: MediaPlayerAgentPlaylist?, issueCode: String?, data: [String: AnyHashable]?)
            case playFailed(errorCode: String)
            
            case stopSucceeded
            case stopFailed(errorCode: String)
            
            case searchSucceeded(message: String?)
            case searchFailed(errorCode: String)
            
            case previousSucceeded(message: String?)
            case previousSuspended(song: MediaPlayerAgentSong?, playlist: MediaPlayerAgentPlaylist?, target: String, data: [String: AnyHashable]?)
            case previousFailed(errorCode: String)
            
            case nextSucceeded(message: String?)
            case nextSuspended(song: MediaPlayerAgentSong?, playlist: MediaPlayerAgentPlaylist?, target: String, data: [String: AnyHashable]?)
            case nextFailed(errorCode: String)
            
            case moveSucceeded(message: String?)
            case moveFailed(errorCode: String)
            
            case pauseSucceeded(message: String?)
            case pauseFailed(errorCode: String)
            
            case resumeSucceeded(message: String?)
            case resumeFailed(errorCode: String?)
            
            case rewindSucceeded(message: String?)
            case rewindFailed(errorCode: String)
            
            case toggleSucceeded(message: String)
            case toggleFailed(errorCode: String)
            
            case getInfoSucceeded(song: MediaPlayerAgentSong?, issueDate: String?, playTime: String?, playListName: String?)
            case getInfoFailed(errorCode: String?)
            
            case handlePlaylistSucceeded
            case handlePlaylistFailed(errorCode: String?)
            
            case handleLyricsSucceeded
            case handleLyricsFailed(errorCode: String?)
        }
    }
}

// MARK: Eventable

extension MediaPlayerAgent.Event: Eventable {
    var payload: [String: AnyHashable] {
        var payloadDictionary: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
            
        if let token = token {
            payloadDictionary["token"] = token
        }

        switch typeInfo {
        case .playSucceeded(let message):
            payloadDictionary["message"] = message
        case .playSuspended(let song, let playlist, let issueCode, let data):
            if let songData = try? JSONEncoder().encode(song),
                let songDictionary = try? JSONSerialization.jsonObject(with: songData, options: []) as? [String: AnyHashable] {
                payloadDictionary["song"] = songDictionary
            }
            
            if let playlistData = try? JSONEncoder().encode(playlist),
                let playlistDictionary = try? JSONSerialization.jsonObject(with: playlistData, options: []) as? [String: AnyHashable] {
                payloadDictionary["playlist"] = playlistDictionary
            }
            
            payloadDictionary["issueCode"] = issueCode
            payloadDictionary["data"] = data
        case .playFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .stopSucceeded:
            break
        case .stopFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .searchSucceeded(let message):
            payloadDictionary["message"] = message
        case .searchFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .previousSucceeded(let message):
            payloadDictionary["message"] = message
        case .previousSuspended(let song, let playlist, let target, let data):
            if let songData = try? JSONEncoder().encode(song),
                let songDictionary = try? JSONSerialization.jsonObject(with: songData, options: []) as? [String: AnyHashable] {
                payloadDictionary["song"] = songDictionary
            }
            
            if let playlistData = try? JSONEncoder().encode(playlist),
                let playlistDictionary = try? JSONSerialization.jsonObject(with: playlistData, options: []) as? [String: AnyHashable] {
                payloadDictionary["playlist"] = playlistDictionary
            }
            
            payloadDictionary["target"] = target
            payloadDictionary["data"] = data
        case .previousFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .nextSucceeded(let message):
            payloadDictionary["message"] = message
        case .nextSuspended(let song, let playlist, let target, let data):
            if let songData = try? JSONEncoder().encode(song),
                let songDictionary = try? JSONSerialization.jsonObject(with: songData, options: []) as? [String: AnyHashable] {
                payloadDictionary["song"] = songDictionary
            }
            
            if let playlistData = try? JSONEncoder().encode(playlist),
                let playlistDictionary = try? JSONSerialization.jsonObject(with: playlistData, options: []) as? [String: AnyHashable] {
                payloadDictionary["playlist"] = playlistDictionary
            }
            
            payloadDictionary["target"] = target
            payloadDictionary["data"] = data
        case .nextFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .moveSucceeded(let message):
            payloadDictionary["message"] = message
        case .moveFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .pauseSucceeded(let message):
            payloadDictionary["message"] = message
        case .pauseFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .resumeSucceeded(let message):
            payloadDictionary["message"] = message
        case .resumeFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .rewindSucceeded(let message):
            payloadDictionary["message"] = message
        case .rewindFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .toggleSucceeded(let message):
            payloadDictionary["message"] = message
        case .toggleFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .getInfoSucceeded(let song, let issueDate, let playTime, let playlistName):
            var infoDictionary = [String: AnyHashable]()
            
            if let songData = try? JSONEncoder().encode(song),
                let songDictionary = try? JSONSerialization.jsonObject(with: songData, options: []) as? [String: AnyHashable] {
                infoDictionary["song"] = songDictionary
            }
            
            infoDictionary["issueDate"] = issueDate
            infoDictionary["playTime"] = playTime
            infoDictionary["playlistName"] = playlistName
            
            payloadDictionary["info"] = infoDictionary
        case .getInfoFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .handlePlaylistSucceeded:
            break
        case .handlePlaylistFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        case .handleLyricsSucceeded:
            break
        case .handleLyricsFailed(let errorCode):
            payloadDictionary["errorCode"] = errorCode
        }
        
        return payloadDictionary
    }
    
    var name: String {
        switch typeInfo {
        case .playSucceeded: return "PlaySucceeded"
        case .playSuspended: return "PlaySuspended"
        case .playFailed: return "PlayFailed"
        case .stopSucceeded: return "StopSucceeded"
        case .stopFailed: return "StopFailed"
        case .searchSucceeded: return "SearchSucceeded"
        case .searchFailed: return "SearchFailed"
        case .previousSucceeded: return "PreviousSucceeded"
        case .previousSuspended: return "PreviousSuspended"
        case .previousFailed: return "PreviousFailed"
        case .nextSucceeded: return "NextSucceeded"
        case .nextSuspended: return "NextSuspended"
        case .nextFailed: return "NextFailed"
        case .moveSucceeded: return "MoveSucceeded"
        case .moveFailed: return "MoveFailed"
        case .pauseSucceeded: return "PauseSucceeded"
        case .pauseFailed: return "PauseFailed"
        case .resumeSucceeded: return "ResumeSucceeded"
        case .resumeFailed: return "ResumeFailed"
        case .rewindSucceeded: return "RewindSucceeded"
        case .rewindFailed: return "RewindFailed"
        case .toggleSucceeded: return "ToggleSucceeded"
        case .toggleFailed: return "ToggleFailed"
        case .getInfoSucceeded: return "GetInfoSucceeded"
        case .getInfoFailed: return "GetInfoFailed"
        case .handlePlaylistSucceeded: return "HandlePlaylistSucceeded"
        case .handlePlaylistFailed: return "HandlePlaylistFailed"
        case .handleLyricsSucceeded: return "HandleLyricsSucceeded"
        case .handleLyricsFailed: return "HandleLyricsFailed"
        }
    }
}
