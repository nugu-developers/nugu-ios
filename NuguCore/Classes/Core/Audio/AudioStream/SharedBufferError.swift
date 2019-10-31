//
//  SharedBufferError.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 02/05/2019.
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

public enum SharedBufferError: Error {
    case writePermissionDenied
    case writerFinished
}

// MARK: - LocalizedError

extension SharedBufferError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .writePermissionDenied:
            return "write proces without permission. (check current Writter)"
        case .writerFinished:
            return "Stream Writer Doens't work any longer"
        }
    }
}
