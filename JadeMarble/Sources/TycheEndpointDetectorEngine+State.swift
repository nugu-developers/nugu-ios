//
//  TycheEpdState.swift
//  JadeMarble
//
//  Created by childc on 2019/11/06.
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

public extension TycheEndPointDetectorEngine {
    enum State {
        /// <#Description#>
        case idle
        /// <#Description#>
        case listening
        /// <#Description#>
        case start
        /// <#Description#>
        case end
        /// <#Description#>
        case timeout
        /// <#Description#>
        case reachToMaxLength
        /// <#Description#>
        case finish
        /// <#Description#>
        case unknown
        /// <#Description#>
        case error
    }
}

extension TycheEndPointDetectorEngine.State {
    init(engineState: Int32) {
        switch engineState {
        case 0:
            self = .listening
        case 1, 3:
            self = .start
        case 2:
            self = .end
        case 4:
            self = .timeout
        case 5:
            self = .reachToMaxLength
        case 6:
            self = .finish
        default:
            self = .unknown
        }
    }
}
