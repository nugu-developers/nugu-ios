//
//  Container+Merge.swift
//  NuguUtils
//
//  Created by DCs-OfficeMBP on 19/06/2019.
//  Revised by 김진님/AI Assistant개발 Cell on 2020/11/27.
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

public extension Dictionary {
    mutating func merge(_ forDictionary: Dictionary) {
        forDictionary.forEach { (targetKey, targetValue) in
            var value = targetValue
            if var originalValue = self[targetKey] as? Dictionary, let targetValue = targetValue as? Dictionary {
                originalValue.merge(targetValue)
                if let mergedValue = originalValue as? Value {
                    value = mergedValue
                }
            } else if var originalValue = self[targetKey] as? [AnyHashable], let targetValue = targetValue as? [AnyHashable] {
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

public extension Array {
    mutating func merge(_ forArray: Array) {
        forArray.enumerated().forEach { index, targetElement in
            var element = targetElement
            guard self.count > index else {
                self.append(element)
                return
            }
            if var originalElement = self[index] as? Array, let targetElement = targetElement as? Array {
                originalElement.merge(targetElement)
                if let mergedElement = originalElement as? Element {
                    element = mergedElement
                }
            } else if var originalElement = self[index] as? [String: AnyHashable], let targetElement = targetElement as? [String: AnyHashable] {
                originalElement.merge(targetElement)
                if let mergedElement = originalElement as? Element {
                    element = mergedElement
                }
            }
            self[index] = element
        }
    }
    
    func merged(with array: Array) -> Array {
        var resultArray = self
        resultArray.merge(array)
        return resultArray
    }
}
