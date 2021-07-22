//
//  DataStreamPlayerState.swift
//  SilverTray
//
//  Created by childc on 2020/04/21.
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

public enum DataStreamPlayerState: Equatable {
    case idle
    case start
    case finish
    case pause
    case resume
    case stop
    case error(_ error: Error)
    
    public static func == (lhs: DataStreamPlayerState, rhs: DataStreamPlayerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.start, .start),
             (.finish, .finish),
             (.pause, .pause),
             (.resume, .resume),
             (.stop, .stop),
             (.error, .error):
            return true
            
        default:
            return false
        }
    }
}
