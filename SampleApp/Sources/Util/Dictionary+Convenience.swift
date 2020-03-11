//
//  Dictionary+Convenience.swift
//  SampleApp
//
//  Created by DCs-OfficeMBP on 2020/03/02.
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

import Foundation

extension Dictionary {
    mutating func merge(_ forDictionary: Dictionary) {
        forDictionary.forEach { (targetKey, targetValue) in
            var value = targetValue
            if var originalValue = self[targetKey] as? Dictionary, let targetValue = targetValue as? Dictionary {
                originalValue.merge(targetValue)
                if let mergedValue = originalValue as? Value {
                    value = mergedValue
                }
            }
            
            updateValue(value, forKey: targetKey)
        }
    }
    
    func merged(with dictionary: Dictionary) -> Dictionary {
        var resultDic = self
        resultDic.merge(dictionary)
        return resultDic
    }
}
