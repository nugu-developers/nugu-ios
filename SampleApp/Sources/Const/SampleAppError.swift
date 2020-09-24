//
//  SampleAppError.swift
//  SampleApp
//
//  Created by yonghoonKwon on 01/07/2019.
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

import NuguLoginKit
import NuguAgents

enum SampleAppError: Error {
    case nilValue(description: String?)
    
    case loginFailed(error: Error)
    case loginUnauthorized(reason: APIErrorReason)
    case loginWithRefreshTokenFailed
    
    case deviceRevoked(reason: SystemAgentRevokeReason)
    
    case internalServiceException
}

// MARK: - LocalizedError

extension SampleAppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .nilValue(let description):
            return description
        case .loginFailed(let error):
            return "login has failed (reason: \(error))"
        case .loginUnauthorized(let reason):
            // 401 invalid_token / user_device_disconnected, user_device_unexpected has been changed into
            // 400 invalid_grant / user_device_disconnected, user_device_unexpected
            // (Due to server develop side's request)
            if reason.statusCode == 401 || reason.statusCode == 400 {
                switch (reason.errorCode, reason.error) {
                case ("user_account_closed", _):
                    return "탈퇴한 사용자입니다."
                case ("user_account_paused", _):
                    return "휴면 상태 사용자입니다."
                case ("user_device_disconnected", _):
                    return "연결 해제된 상태입니다."
                case ("user_device_unexpected", _):
                    return "내부 검증 토큰이 불일치합니다."
                case (_, "unauthorized"):
                    return "인가되지 않은 사용자 정보입니다."
                case (_, "unauthorized_client"):
                    return "인가되지 않은 클라이언트입니다."
                case (_, "invalid_token"):
                    return "유효하지 않은 토큰입니다."
                case (_, "invalid_client"):
                    return "유효하지 않은 클라이언트 정보입니다."
                case (_, "access_denied"):
                    return "접근이 거부되었습니다."
                default:
                    break
                }
            }
            return "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "NuguSample")의 누구 서비스가 종료되었습니다."
        case .loginWithRefreshTokenFailed:
            return "Login with refresh token has failed"
        case .deviceRevoked(reason: let reason) where [.unknown, .revokeDevice].contains(reason):
            return "누구 앱과의 연결이 해제되었습니다. 다시 연결해주세요."
        case .deviceRevoked(reason: let reason) where reason == .withdrawnUser:
            return "탈퇴된 사용자입니다. 다시 연결해주세요."
        case .internalServiceException:
            return "NUGU 서비스와 연결할 수 없습니다. 잠시 후 다시 말씀해주세요."
        default:
            return "Undefined error"
        }
    }
}

// MARK: - Convert from NuguLoginKitError

extension SampleAppError {
    static func parseFromNuguLoginKitError(error: NuguLoginKitError) -> SampleAppError {
        guard case .apiError(let apiError) = error,
            case .invalidStatusCode(let apiErrorReason) = apiError else {
            return .loginFailed(error: error)
        }
        return .loginUnauthorized(reason: apiErrorReason)
    }
}
