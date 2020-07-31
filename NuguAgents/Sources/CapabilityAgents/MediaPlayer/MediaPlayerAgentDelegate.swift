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

public protocol MediaPlayerAgentDelegate: class {
    func mediaPlayerAgentRequestContext() -> MediaPlayerAgentContext?
    
    func mediaPlayerAgentReceivePlay(payload: MediaPlayerAgentDirectivePayload.Play, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Play) -> Void))
    func mediaPlayerAgentReceiveStop(playServiceId: String, token: String, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Stop) -> Void))
    func mediaPlayerAgentReceiveSearch(payload: MediaPlayerAgentDirectivePayload.Search, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Search) -> Void))
    func mediaPlayerAgentReceivePrevious(payload: MediaPlayerAgentDirectivePayload.Previous, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Previous) -> Void))
    func mediaPlayerAgentReceiveNext(payload: MediaPlayerAgentDirectivePayload.Next, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Next) -> Void))
    func mediaPlayerAgentReceiveMove(payload: MediaPlayerAgentDirectivePayload.Move, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Move) -> Void))
    func mediaPlayerAgentReceivePause(playServiceId: String, token: String, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Pause) -> Void))
    func mediaPlayerAgentReceiveResume(playServiceId: String, token: String, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Resume) -> Void))
    func mediaPlayerAgentReceiveRewind(playServiceId: String, token: String, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Rewind) -> Void))
    func mediaPlayerAgentReceiveToggle(payload: MediaPlayerAgentDirectivePayload.Toggle, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.Toggle) -> Void))
    func mediaPlayerAgentReceiveGetInfo(playServiceId: String, token: String, dialogRequestId: String, completion: @escaping ((MediaPlayerAgentProcessResult.GetInfo) -> Void))
}
