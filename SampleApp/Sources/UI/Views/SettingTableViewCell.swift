//
//  SettingTableViewCell.swift
//  SampleApp
//
//  Created by jin kim on 2020/05/28.
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

final class SettingTableViewCell: UITableViewCell {
    var isEnabled: Bool {
        get {
            isUserInteractionEnabled
        }
        set {
            isUserInteractionEnabled = newValue
            menuSwitch.isEnabled = newValue
            textLabel?.isEnabled = newValue
            detailTextLabel?.isEnabled = newValue
        }
    }
    var onSwitchValueChanged: ((_ isOn: Bool) -> Void)?

    // MARK: Properties
    
    @IBOutlet private weak var menuSwitch: UISwitch!
    
    func configure(text: String, isSwitchOn: Bool? = nil, detailText: String? = nil) {
        textLabel?.text = text
        textLabel?.textColor = .black
        
        detailTextLabel?.text = detailText
        detailTextLabel?.textColor = .systemBlue
        
        if let isSwitchOn = isSwitchOn {
            menuSwitch.isOn = isSwitchOn
            menuSwitch.isHidden = false
        } else {
            menuSwitch.isHidden = true
        }
    }
}

private extension SettingTableViewCell {
    @IBAction func menuSwitchValueChanged(_ menuSwitch: UISwitch) {
        onSwitchValueChanged?(menuSwitch.isOn)
    }
}
