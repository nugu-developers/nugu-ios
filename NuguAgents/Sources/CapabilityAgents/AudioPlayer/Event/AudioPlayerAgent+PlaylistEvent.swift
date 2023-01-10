//
//  AudioPlayerAgent+PlaylistEvent.swift
//  NuguAgents
//
//  Copyright © 2023 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation

// MARK: - Event

extension AudioPlayerAgent {
    struct PlaylistEvent {
        let typeInfo: TypeInfo
        let playServiceId: String
        
        enum TypeInfo {
            case playlistItemSelected(token: String, postback: [String: AnyHashable])
            case playlistFavoriteSelected(token: String, postback: [String: AnyHashable])
            case modifyPlaylist(deletedTokens: [String], tokens: [String])
        }
    }
}

// MARK: - Eventable

extension AudioPlayerAgent.PlaylistEvent: Eventable {
    var payload: [String : AnyHashable] {
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
        }
        return eventPayload
    }
    
    var name: String {
        switch typeInfo {
        case .playlistFavoriteSelected, .playlistItemSelected:
            return "ElementSelected"
        case .modifyPlaylist:
            return "ModifyPlaylist"
        }
    }
}
