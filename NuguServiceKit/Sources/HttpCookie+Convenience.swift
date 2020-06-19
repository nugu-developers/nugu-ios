//
//  HttpCookie+Convenience.swift
//  NuguServiceKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/06/15.
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
import WebKit

extension HTTPCookie {
    var stringValue: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
        
        var cookieStrArray = [String]()
        cookieStrArray.append("'\(self.name)=\(self.value)'")
        cookieStrArray.append("'domain=\(self.domain)'")
        cookieStrArray.append("'path=\(self.path)'")
        if let date = self.expiresDate {
            cookieStrArray.append("'expires=\(dateFormatter.string(from: date))'")
        }
        
        let cookieStr = cookieStrArray.joined(separator: "; ")
        return "document.cookie=\(cookieStr)"
    }
}

// MARK: - Array + HTTPCookie

extension Array where Element == HTTPCookie {
    var stringValue: String {
        return self.map({ (element) -> String in
            return element.stringValue
        }).joined(separator: "; ")
    }
}
