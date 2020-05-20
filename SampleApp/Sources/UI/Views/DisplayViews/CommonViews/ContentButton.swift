//
//  ContentButton.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/15.
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

import UIKit

final class ContentButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setCustomUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setCustomUI()
    }
    
    private func setCustomUI() {
        layer.cornerRadius = 4.0
        layer.borderColor = UIColor(rgbHexValue: 0xd8d8d8).cgColor
        layer.borderWidth = 1.0
        setTitleColor(UIColor.textColor(rgbHexString: "444444"), for: .normal)
        setTitleColor(UIColor.textColor(rgbHexString: "686868"), for: .highlighted)
        contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 16.0, bottom: 10.0, right: 16.0)
    }
    
    override public var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor(red: 0, green: 0, blue: 0, alpha: 0.1) : .white
        }
    }
}
