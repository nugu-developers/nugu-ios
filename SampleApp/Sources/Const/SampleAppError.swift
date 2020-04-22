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

enum SampleAppError: Error {
    case nilValue(description: String?)
    
    case loginFailed(error: Error)
    case loginUnauthorized(reason: APIErrorReason)
    case loginWithRefreshTokenFailed
    
    case deviceRevoked
}

// MARK: - LocalizedError

extension SampleAppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .nilValue(let description):
            return description
        case .loginFailed(let error):
            return "login has failed (reason: \(error))"
        case .loginUnauthorized:
            // Sample application does not present any detail informations about unauthorized reason.
            // Please check APIErrorReason for detail reason of unauthorization.
            return "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "NuguSample")의 누구 서비스가 종료되었습니다."
        case .loginWithRefreshTokenFailed:
            return "Login with refresh token has failed"
        case .deviceRevoked:
            return "누구 앱과의 연결이 해제되었습니다. 다시 연결해주세요."
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
