//
//  ASRResult.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2019/06/10.
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

import NuguCore

/// The result of `startRecognition` request.
public enum ASRResult {
    /// 음성 인식 결과 없음
    /// - Parameter header: The header of the originally handled directive.
    case none(header: Downstream.Header)
    /// 사용자 발화의 일부분
    /// - Parameter text: Recognized utterance.
    /// - Parameter header: The header of the originally handled directive.
    case partial(text: String, header: Downstream.Header)
    /// 사용자 발화의 전체 문장
    /// - Parameter text: Recognized utterance.
    /// - Parameter header: The header of the originally handled directive.
    case complete(text: String, header: Downstream.Header)
    /// 음성 인식 요청 취소
    case cancel(header: Downstream.Header? = nil)
    /// The `ASR.ExpectSpeech` directive has been cancelled.
    case cancelExpectSpeech
    /// 음성 인식 결과 실패
    /// - Parameter error:
    /// - Parameter header: The header of the originally handled directive.
    case error(_ error: Error, header: Downstream.Header? = nil)
}
