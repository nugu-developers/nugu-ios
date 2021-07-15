//
//  ASRBeepPlayerResourceURL.swift
//  NuguClientKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2021/02/26.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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

public struct ASRBeepPlayerResourcesURL {
    let startBeepResourceUrl: URL?
    let successBeepResourceUrl: URL?
    let failBeepResourceUrl: URL?
    
    public init(
        startBeepResourceUrl: URL? = Bundle.main.url(forResource: "listening_start", withExtension: "wav"),
        successBeepResourceUrl: URL? = Bundle.main.url(forResource: "listening_end", withExtension: "wav"),
        failBeepResourceUrl: URL? = Bundle.main.url(forResource: "responsefail", withExtension: "wav")
    ) {
        self.startBeepResourceUrl = startBeepResourceUrl
        self.successBeepResourceUrl = successBeepResourceUrl
        self.failBeepResourceUrl = failBeepResourceUrl
    }
}
