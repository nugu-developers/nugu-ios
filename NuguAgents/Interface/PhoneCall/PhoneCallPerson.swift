//
//  PhoneCallPerson.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 2020/04/29.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

public struct PhoneCallPerson: Codable {
    public struct Contact: Codable {
        public struct BusinessHours: Codable {
            public let open: String?
            public let close: String?
            
            init(open: String?, close: String?) {
                self.open = open
                self.close = close
            }
        }
        
        public struct History: Codable {
            public let time: String
            public let type: String
            
            init(time: String, type: String) {
                self.time = time
                self.type = type
            }
        }
        
        public let type: String
        public let label: String?
        public let profileImgUrl: String?
        public let category: String?
        public let address: String?
        public let number: String?
        public let businessHours: BusinessHours?
        public let history: History?
        public let numInCallHistory: String
        
        init(
            type: String,
            label: String?,
            profileImgUrl: String?,
            category: String?,
            address: String?,
            number: String?,
            businessHours: BusinessHours?,
            history: History?,
            numInCallHistory: String
        ) {
            self.type = type
            self.label = label
            self.profileImgUrl = profileImgUrl
            self.category = category
            self.address = address
            self.number = number
            self.businessHours = businessHours
            self.history = history
            self.numInCallHistory = numInCallHistory
        }
    }
    
    public let name: String
    public let token: String
    public let score: String?
    public let contacts: [Contact]?
    
    init(name: String, token: String, score: String?, contacts: [Contact]?) {
        self.name = name
        self.token = token
        self.score = score
        self.contacts = contacts
    }
}
