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
import NuguUtils

/// The result of `startRecognition` request.
public enum ASRResult: Codable {
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
    
    enum CodingKeys: CodingKey {
        case idx
        case associatedValue1
        case associatedValue2
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idx = try container.decode(Int.self, forKey: .idx)

        switch idx {
        case 0:
            let header = try container.decode(Downstream.Header.self, forKey: .associatedValue1)
            self = .none(header: header)

        case 1:
            let text = try container.decode(String.self, forKey: .associatedValue1)
            let header = try container.decode(Downstream.Header.self, forKey: .associatedValue2)
            self = .partial(text: text, header: header)

        case 2:
            let text = try container.decode(String.self, forKey: .associatedValue1)
            let header = try container.decode(Downstream.Header.self, forKey: .associatedValue2)
            self = .complete(text: text, header: header)

        case 3:
            let header = try container.decode(Downstream.Header.self, forKey: .associatedValue1)
            self = .cancel(header: header)

        case 4:
            self = .cancelExpectSpeech

        case 5:
            var asrError: Error
            do {
                asrError = try container.decode(ASRError.self, forKey: .associatedValue1)
            } catch {
                asrError = try container.decode(DummyASRError.self, forKey: .associatedValue1)
            }

            let header = try container.decode(Downstream.Header.self, forKey: .associatedValue2)
            self = .error(asrError, header: header)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unmatched case"))}
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .none(header):
            try container.encode(0, forKey: .idx)
            try container.encode(header, forKey: .associatedValue1)
        case let .partial(text, header):
            try container.encode(1, forKey: .idx)
            try container.encode(text, forKey: .associatedValue1)
            try container.encode(header, forKey: .associatedValue2)
        case let .complete(text, header):
            try container.encode(2, forKey: .idx)
            try container.encode(text, forKey: .associatedValue1)
            try container.encode(header, forKey: .associatedValue2)
        case let .cancel(header):
            try container.encode(3, forKey: .idx)
            try container.encode(header, forKey: .associatedValue1)
        case .cancelExpectSpeech:
            try container.encode(4, forKey: .idx)
        case let .error(error, header):
            if let asrError = error as? ASRError {
                try container.encode(asrError, forKey: .associatedValue1)
            } else {
                let dummyError = DummyASRError(code: 0, name: error.localizedDescription)
                try container.encode(dummyError, forKey: .associatedValue1)
            }

            try container.encode(header, forKey: .associatedValue2)
        }
    }
}

public struct DummyASRError: CodableError {
    public let code: Int
    public let name: String
}
