//
//  AudioPlayerSettingsTemplate.swift
//  SampleApp
//
//  Created by jin kim on 2020/03/13.
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

struct AudioPlayerSettingsTemplate: Decodable {
    let favorite: Bool?
    let `repeat`: Repeat?
    let shuffle: Bool?
    
    enum CodingKeys: String, CodingKey {
        case favorite
        case `repeat`
        case shuffle
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        favorite = try? container.decodeIfPresent(Bool.self, forKey: .favorite)
        `repeat` = try? container.decodeIfPresent(Repeat.self, forKey: .repeat)
        shuffle = try? container.decodeIfPresent(Bool.self, forKey: .shuffle)
    }
    
    enum Repeat: String, Decodable, CodingKey {
        case all = "ALL"
        case one = "ONE"
        case none = "NONE"
    }
}
