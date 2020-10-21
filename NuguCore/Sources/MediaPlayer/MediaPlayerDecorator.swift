//
//  MediaPlayerDecorator.swift
//  NuguCore
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/10/20.
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

public protocol MediaPlayerDecorator: MediaPlayable {
    var internalPlayer: MediaPlayable? { get }
}

public extension MediaPlayerDecorator {
    var offset: TimeIntervallic {
        return internalPlayer?.offset ?? NuguTimeInterval(seconds: 0)
    }
    var duration: TimeIntervallic {
        return internalPlayer?.duration ?? NuguTimeInterval(seconds: 0)
    }
    var volume: Float {
        get {
            internalPlayer?.volume ?? 1.0
        }
        set(newValue) {
            internalPlayer?.volume = newValue
        }
    }
    
    func play() {
        internalPlayer?.play()
    }
    
    func stop() {
        internalPlayer?.stop()
    }
    
    func pause() {
        internalPlayer?.pause()
    }
    
    func resume() {
        internalPlayer?.resume()
    }
    
    func seek(to offset: TimeIntervallic, completion: ((Result<Void, Error>) -> Void)?) {
        internalPlayer?.seek(to: offset, completion: completion)
    }
}
