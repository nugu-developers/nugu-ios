//
//  DownstreamDataTimeoutPreprocessor.swift
//  NuguCore
//
//  Created by MinChul Lee on 2019/11/25.
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

import NuguInterface

public class DownstreamDataTimeoutPreprocessor: DownstreamDataPreprocessable {
    private let timeoutPreprocessorDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.timeout_preprocessor", qos: .userInitiated)
    
    private var timeoutDialogRequestIds = [String]()
    
    public init() {}
    
    public func preprocess<T>(message: T) -> T? where T: DownstreamMessageable {
        timeoutPreprocessorDispatchQueue.sync {
            guard self.timeoutDialogRequestIds.contains(message.header.dialogRequestId) == false else {
                log.warning("\(message.header.dialogRequestId) was timeout")
                return nil
            }
            return message
        }
    }
}

// MARK: - Internal

extension DownstreamDataTimeoutPreprocessor {
    func appendTimeoutDialogRequestId(_ dialogRequestId: String) {
        timeoutPreprocessorDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            self.timeoutDialogRequestIds.append(dialogRequestId)
            if self.timeoutDialogRequestIds.count > 100 {
                self.timeoutDialogRequestIds.removeFirst()
            }
        }
    }
}
