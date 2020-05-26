//
//  Score1Template.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/13.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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
struct Score1Template: Decodable {
    let playServiceId: String
    let token: String
    let duration: DisplayCommonTemplate.Common.Duration?
    let title: DisplayCommonTemplate.Common.Title
    let background: DisplayCommonTemplate.Common.Background?
    let content: Content
    let grammarGuide: [String]?
    
    struct Content: Decodable {
        let schedule: DisplayCommonTemplate.Common.Text?
        let status: DisplayCommonTemplate.Common.Text
        let match: [DisplayCommonTemplate.Common.Match]
    }
}
