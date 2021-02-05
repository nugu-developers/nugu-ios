//
//  MediaPlayerAgentDelegate.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/06.
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

import NuguCore

/// The `MediaPlayerAgentDelegate` protocol defines methods that a delegate of a `MediaPlayerAgent` object can implement to receive directives or request context.
public protocol MediaPlayerAgentDelegate: class {
    
    /// Provide a context of `MediaPlayerAgent`.
    ///
    /// This function should return as soon as possible to reduce request delay.
    /// - Returns: The context for `MediaPlayerAgentContext`
    func mediaPlayerAgentRequestContext() -> MediaPlayerAgentContext?
    
    /// Called method when a directive 'Play' is received.
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.   
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceivePlay(payload: MediaPlayerAgentDirectivePayload.Play, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Play) -> Void))
    
    /// Called method when a directive 'Stop' is received.
    /// - Parameters:
    ///   - playServiceId: The unique identifier to specify play service.
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveStop(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Stop) -> Void))
    
    /// Called method when a directive 'Search' is received.
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveSearch(payload: MediaPlayerAgentDirectivePayload.Search, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Search) -> Void))
    
    /// Called method when a directive 'Previous' is received.
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceivePrevious(payload: MediaPlayerAgentDirectivePayload.Previous, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Previous) -> Void))
    
    /// Called method when a directive 'Next' is received.
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveNext(payload: MediaPlayerAgentDirectivePayload.Next, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Next) -> Void))
    
    /// Called method when a directive 'Move' is received.
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveMove(payload: MediaPlayerAgentDirectivePayload.Move, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Move) -> Void))
    
    /// Called method when a directive 'Pause' is received.
    /// - Parameters:
    ///   - playServiceId: The unique identifier to specify play service.
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceivePause(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Pause) -> Void))
    
    /// Called method when a directive 'Resume' is received.
    /// - Parameters:
    ///   - playServiceId: The unique identifier to specify play service.
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveResume(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Resume) -> Void))
    
    /// Called method when a directive 'Rewind' is received.
    /// - Parameters:
    ///   - playServiceId: The unique identifier to specify play service.
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveRewind(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Rewind) -> Void))
    
    /// Called method when a directive 'Toggle' is received.
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveToggle(payload: MediaPlayerAgentDirectivePayload.Toggle, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Toggle) -> Void))
    
    /// Called method when a directive 'GetInfo' is received.
    /// - Parameters:
    ///   - playServiceId: The unique identifier to specify play service.
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveGetInfo(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.GetInfo) -> Void))
    
    /// Called method when a directive 'HandlePlaylist' is received.
    /// - Parameters:
    ///   - playServiceId: The unique identifier to specify play service.
    ///   - action: <#action description#>
    ///   - target: <#target description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceivePlaylist(playServiceId: String, action: String, target: String?, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.HandlePlaylist) -> Void))
    
    /// Called method when a directive 'HandleLyrics' is received.
    /// - Parameters:
    ///   - playServiceId: The unique identifier to specify play service.
    ///   - action: <#action description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: A block to call when you are finished performing the action.
    func mediaPlayerAgentReceiveLyrics(playServiceId: String, action: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.HandleLyrics) -> Void))
}
