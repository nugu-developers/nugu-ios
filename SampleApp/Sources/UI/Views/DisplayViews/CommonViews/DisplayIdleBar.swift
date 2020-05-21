//
//  DisplayIdleBar.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/12.
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

import NuguUIKit

final class DisplayIdleBar: UIView {
    @IBOutlet private weak var lineView: UIView!
    @IBOutlet private weak var nuguButton: NuguButton!
    @IBOutlet private weak var chipsView: NuguChipsView!
    
    var onNuguButtonClick: (() -> Void)?
    
    var onChipsSelect: ((_ text: String?) -> Void)? {
        didSet {
            chipsView.onChipsSelect = onChipsSelect
        }
    }
    
    var chipsData: [NuguChipsButton.NuguChipsButtonType] = [] {
        didSet {
            chipsView.chipsData = chipsData
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromXib()
    }
    
    func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("DisplayIdleBar", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        backgroundColor = .clear
        nuguButton.addTarget(self, action: #selector(nuguButtonDidClick(button:)), for: .touchUpInside)
    }
    
    func lineViewIsHidden(hidden: Bool) {
        lineView.isHidden = hidden
    }
    
    @objc func nuguButtonDidClick(button: NuguButton) {
        onNuguButtonClick?()
    }
}
