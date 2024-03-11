//
//  AudioPlayerAgent+PlaylistEvent.swift
//  NuguAgents
//
//  Copyright © 2023 SK Telecom Co., Ltd. All rights reserved.
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

// MARK: - Event

extension AudioPlayerAgent {
    struct PlaylistEvent {
        let typeInfo: TypeInfo
        let playServiceId: String?
        
        enum TypeInfo {
            case playlistItemSelected(token: String, postback: [String: AnyHashable])
            case playlistFavoriteSelected(token: String, postback: [String: AnyHashable])
            case modifyPlaylist(deletedTokens: [String], tokens: [String])
            
            case showPlaylistSucceeded
            case showPlaylistFailed(error: [String: String])
        }
    }
}

// MARK: - Eventable

extension AudioPlayerAgent.PlaylistEvent: Eventable {
    var payload: [String: AnyHashable] {
        var eventPayload: [String: AnyHashable] = [
            "playServiceId": playServiceId
        ]
        switch typeInfo {
        case .playlistFavoriteSelected(token: let playlistItemToken, postback: let postback):
            eventPayload["token"] = playlistItemToken
            eventPayload["postback"] = postback
        case .playlistItemSelected(token: let playlistItemToken, postback: let postback):
            eventPayload["token"] = playlistItemToken
            eventPayload["postback"] = postback
        case .modifyPlaylist(deletedTokens: let deletedTokens, tokens: let tokens):
            eventPayload["deletedTokens"] = deletedTokens
            eventPayload["tokens"] = tokens
        case .showPlaylistSucceeded:
            break
        case .showPlaylistFailed(error: let error):
            eventPayload["error"] = error
        }
        
        return eventPayload
    }
    
    var name: String {
        switch typeInfo {
        case .playlistFavoriteSelected, .playlistItemSelected:
            return "ElementSelected"
        case .modifyPlaylist:
            return "ModifyPlaylist"
        case .showPlaylistSucceeded:
            return "ShowPlaylistSucceeded"
        case .showPlaylistFailed:
            return "ShowPlaylistFailed"
        }
    }
}
