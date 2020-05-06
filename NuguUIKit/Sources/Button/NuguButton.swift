//
//  NuguButton.swift
//  NuguUIKit
//
//  Created by jin kim on 03/07/2019.
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

final public class NuguButton: UIButton {
    
    // MARK: - NuguButton.NuguButtonType
    
    public enum NuguButtonType {
        case fab(color: NuguButtonColor)
        case button(color: NuguButtonColor)
        
        public enum NuguButtonColor: String {
            case blue
            case white
        }
    }
    
    // MARK: - Public Properties (configurable variables)
    
    public var nuguButtonType: NuguButtonType = .fab(color: .blue) {
        didSet {
            setButtonImages()
        }
    }
    
    // MARK: - Override
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setButtonImages()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setButtonImages()
    }
}

// MARK: - Private

private extension NuguButton {
    func setButtonImages() {
        switch nuguButtonType {
        case .fab(let color):
            setImage(UIImage(named: "fab_\(color.rawValue)", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .normal)
            setImage(UIImage(named: "fab_\(color.rawValue)_pressed", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .highlighted)
            setImage(UIImage(named: "fab_disabled", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .disabled)
        case .button(let color):
            setImage(UIImage(named: "btn_\(color.rawValue)", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .normal)
            setImage(UIImage(named: "btn_\(color.rawValue)_pressed", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .highlighted)
            setImage(UIImage(named: "btn_disabled", in: Bundle(for: NuguButton.self), compatibleWith: nil), for: .disabled)
        }
    }
}
