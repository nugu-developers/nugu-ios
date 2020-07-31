//
//  MediaPlayerAgentProcessResult.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/07/27.
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

public enum MediaPlayerAgentProcessResult {
    
    // MARK: Play
    
    public enum Play {
        case succeeded(message: String?)
        case suspended(song: MediaPlayerAgentSong?, playlist: MediaPlayerAgentPlaylist?, issueCode: String?)
        case failed(errorCode: String)
    }
    
    // MARK: Stop
    
    public enum Stop {
        case succeeded
        case failed(errorCode: String)
    }
    
    // MARK: Search
    
    public enum Search {
        case succeeded(message: String?)
        case failed(message: String)
    }
    
    // MARK: Previous
    
    public enum Previous {
        case succeeded(message: String?)
        case suspended(song: MediaPlayerAgentSong?, playlist: MediaPlayerAgentPlaylist?, target: String)
        case failed(errorCode: String)
    }
    
    // MARK: Next
    
    public enum Next {
        case succeeded(message: String?)
        case suspended(song: MediaPlayerAgentSong?, playlist: MediaPlayerAgentPlaylist?, target: String)
        case failed(errorCode: String)
    }
    
    // MARK: Move
    
    public enum Move {
        case succeeded(message: String?)
        case failed(errorCode: String)
    }
    
    // MARK: Pause
    
    public enum Pause {
        case succeeded(message: String?)
        case failed(errorCode: String)
    }
    
    // MARK: Resume
    
    public enum Resume {
        case succeeded(message: String?)
        case failed(errorCode: String?)
    }
    
    // MARK: Rewind
    
    public enum Rewind {
        case succeeded(message: String?)
        case failed(errorCode: String)
    }
    
    // MARK: Toggle
    
    public enum Toggle {
        case succeeded(message: String)
        case failed(errorCode: String)
    }
    
    public enum GetInfo {
        case succeeded(song: MediaPlayerAgentSong?, issueDate: String?, playTime: String?, playListName: String?)
        case failed(errorCode: String?)
    }
}
