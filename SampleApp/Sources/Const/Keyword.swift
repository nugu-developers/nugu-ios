//
//  Keyword.swift
//  SampleApp
//
//  Created by MinChul Lee on 2020/04/13.
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

import NuguClientKit

enum Keyword: Int, CustomStringConvertible, CaseIterable {
    case aria = 0 // ɑriɑ
    case tinkerbell = 3 // tɪŋkəbel
    
    var description: String {
        switch self {
        case .aria:
            return "아리아"
        case .tinkerbell:
            return "팅커벨"
        }
    }
    
    var keywordSource: KeywordSource {
        return KeywordSource(
            keyword: description,
            netFileUrl: netFile,
            searchFileUrl: searchFile
        )
    }
    
    private var netFile: URL {
        switch self {
        case .aria:
            return Bundle.main.url(forResource: "skt_trigger_am_aria", withExtension: "raw")!
        case .tinkerbell:
            return Bundle.main.url(forResource: "skt_trigger_am_tinkerbell", withExtension: "raw")!
        }
    }
    
    private var searchFile: URL {
        switch self {
        case .aria:
            return Bundle.main.url(forResource: "skt_trigger_search_aria", withExtension: "raw")!
        case .tinkerbell:
            return Bundle.main.url(forResource: "skt_trigger_search_tinkerbell", withExtension: "raw")!
        }
    }
}
