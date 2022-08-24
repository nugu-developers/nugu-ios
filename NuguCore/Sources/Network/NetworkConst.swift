//
//  NetworkConst.swift
//  NuguCore
//
//  Created by jin kim on 29/04/2019.
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

enum NetworkConst {
    static var userAgent: String {
        return [openSdkVersion(), clientVersion()].joined(separator: " ")
    }
}

private extension NetworkConst {
    static func openSdkVersion() -> String {
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        return "OpenSDK/" + (Bundle(for: AuthorizationStore.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0")
        #else
        // FIXME: 현재는 SPM에서 버전을 가져올 방법이 없다.
        return "OpenSDK/1.7.4"
        #endif
    }
    
    static func clientVersion() -> String {
        return "Client/" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0")
    }
}
