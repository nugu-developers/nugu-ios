//
//  UIColor+Convenience.swift
//  NuguUIKit
//
//  Created by yonghoonKwon on 18/07/2019.
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

import UIKit

public extension UIColor {
    convenience init(
        rgbHexValue rgbValue: Int,
        alpha alphaDegree: CGFloat = 1.0
        ) {
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
            blue: CGFloat((rgbValue & 0xFF)) / 255.0,
            alpha: alphaDegree
        )
    }
    
    convenience init?(rgbHexString: String?) {
        guard let rgbHexString = rgbHexString,
            let rgbHexValue = Int(rgbHexString, radix: 16) else { return nil }
        self.init(rgbHexValue: rgbHexValue)
    }
    
    static func backgroundColor(rgbHexString: String?) -> UIColor? {
        return UIColor(rgbHexString: rgbHexString) ?? UIColor.white
    }
    
    static func textColor(rgbHexString: String?) -> UIColor? {
        return UIColor(rgbHexString: rgbHexString) ?? UIColor.black
    }
    
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}
