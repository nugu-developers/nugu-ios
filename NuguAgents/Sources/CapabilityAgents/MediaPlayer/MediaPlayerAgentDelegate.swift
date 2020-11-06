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

/// <#Description#>
public protocol MediaPlayerAgentDelegate: class {
    /// <#Description#>
    func mediaPlayerAgentRequestContext() -> MediaPlayerAgentContext?
    
    /// <#Description#>
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.   
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceivePlay(payload: MediaPlayerAgentDirectivePayload.Play, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Play) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveStop(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Stop) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveSearch(payload: MediaPlayerAgentDirectivePayload.Search, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Search) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceivePrevious(payload: MediaPlayerAgentDirectivePayload.Previous, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Previous) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveNext(payload: MediaPlayerAgentDirectivePayload.Next, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Next) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveMove(payload: MediaPlayerAgentDirectivePayload.Move, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Move) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceivePause(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Pause) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveResume(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Resume) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveRewind(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Rewind) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - payload: <#payload description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveToggle(payload: MediaPlayerAgentDirectivePayload.Toggle, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.Toggle) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - token: <#token description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveGetInfo(playServiceId: String, token: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.GetInfo) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - action: <#action description#>
    ///   - target: <#target description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceivePlaylist(playServiceId: String, action: String, target: String?, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.HandlePlaylist) -> Void))
    
    /// <#Description#>
    /// - Parameters:
    ///   - playServiceId: <#playServiceId description#>
    ///   - action: <#action description#>
    ///   - header: The header of the originally handled directive.
    ///   - completion: <#completion description#>
    func mediaPlayerAgentReceiveLyrics(playServiceId: String, action: String, header: Downstream.Header, completion: @escaping ((MediaPlayerAgentProcessResult.HandleLyrics) -> Void))
}
