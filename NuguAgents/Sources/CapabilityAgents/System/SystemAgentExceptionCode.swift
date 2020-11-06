//
//  SystemAgentExceptionCode.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2019/11/28.
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

/// <#Description#>
public enum SystemAgentExceptionCode: Equatable {
    /// <#Description#>
    public enum Fail: String, Codable, Equatable {
        case unauthorizedRequestException = "UNAUTHORIZED_REQUEST_EXCEPTION"
        case playRouterProcessingException = "PLAY_ROUTER_PROCESSING_EXCEPTION"
        case ttsSpeakingException = "TTS_SPEAKING_EXCEPTION"
        case internalServiceException = "INTERNAL_SERVICE_EXCEPTION"
    }
    
    /// <#Description#>
    public enum Warning: String, Codable, Equatable {
        case asrRecognizingException = "ASR_RECOGNIZING_EXCEPTION"
    }
    
    case fail(code: Fail)
    case warning(code: Warning)
}
