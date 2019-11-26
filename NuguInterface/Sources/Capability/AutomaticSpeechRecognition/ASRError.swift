//
//  ASRError.swift
//  NuguInterface
//
//  Created by MinChul Lee on 2019/09/30.
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
public enum ASRError {
    /// 10초(default) 이내 음성 인결 결과 수신 실패.
    case responseTimeout
    /// Recognize event 시작 후 10초(default) 동안 사용자가 발화하지 않음.
    case listeningTimeout
    /// 음성 인식 시작 실패
    case listenFailed
    /// 음성 인식 실패
    case recognizeFailed
}
