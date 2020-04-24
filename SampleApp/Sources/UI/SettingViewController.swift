//
//  SettingViewController.swift
//  SampleApp
//
//  Created by jin kim on 17/06/2019.
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

import KeenSense

final class SettingViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet private weak var nuguServiceSwitch: UISwitch!
    @IBOutlet private weak var wakeupWordSwitch: UISwitch!
    @IBOutlet private weak var wakeupWordButton: UIButton!
    @IBOutlet private weak var speechStartBeepSwitch: UISwitch!
    @IBOutlet private weak var speechSuccessBeepSwitch: UISwitch!
    @IBOutlet private weak var speechFailBeepSwitch: UISwitch!
    
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nuguServiceSwitch.isOn = UserDefaults.Standard.useNuguService
        wakeupWordSwitch.isOn = UserDefaults.Standard.useWakeUpDetector
        
        let wakeupWordValue = UserDefaults.Standard.wakeUpWord
        wakeupWordButton.setTitle(Keyword(rawValue: wakeupWordValue)?.description, for: .normal)
        speechStartBeepSwitch.isOn = UserDefaults.Standard.useAsrStartSound
        speechSuccessBeepSwitch.isOn = UserDefaults.Standard.useAsrSuccessSound
        speechFailBeepSwitch.isOn = UserDefaults.Standard.useAsrFailSound
        
        setEnableabilityByNuguServiceUsage()
    }
}

private extension SettingViewController {
    func setEnableabilityByNuguServiceUsage() {
        wakeupWordSwitch.isEnabled = nuguServiceSwitch.isOn
        wakeupWordButton.isEnabled = nuguServiceSwitch.isOn
        speechStartBeepSwitch.isEnabled = nuguServiceSwitch.isOn
        speechSuccessBeepSwitch.isEnabled = nuguServiceSwitch.isOn
        speechFailBeepSwitch.isEnabled = nuguServiceSwitch.isOn
    }
}

private extension SettingViewController {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func nuguServiceUsageValueChanged(_ switch: UISwitch) {
        UserDefaults.Standard.useNuguService = nuguServiceSwitch.isOn
        setEnableabilityByNuguServiceUsage()
    }
    
    @IBAction func wakeUpWordUsageValueChanged(_ switch: UISwitch) {
        UserDefaults.Standard.useWakeUpDetector = wakeupWordSwitch.isOn
    }
    
    @IBAction func wakeUpWordButtonDidClick(_ button: UIButton) {
        let wakeUpWordActionSheet = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        Keyword.allCases.forEach { [weak self] (keyword) in
            let action = UIAlertAction(
                title: keyword.description,
                style: .default) { [weak self] _ in
                    self?.wakeupWordButton.setTitle(keyword.description, for: .normal)
                    
                    UserDefaults.Standard.wakeUpWord = keyword.rawValue
            }
            
            wakeUpWordActionSheet.addAction(action)
        }
        
        present(wakeUpWordActionSheet, animated: true)
    }
    
    @IBAction func asrStartBeepUsageValueChanged(_ switch: UISwitch) {
        UserDefaults.Standard.useAsrStartSound = speechStartBeepSwitch.isOn
    }
    
    @IBAction func asrSuccessBeepUsageValueChanged(_ switch: UISwitch) {
        UserDefaults.Standard.useAsrSuccessSound = speechSuccessBeepSwitch.isOn
    }
    
    @IBAction func asrFailBeepUsageValueChanged(_ switch: UISwitch) {
        UserDefaults.Standard.useAsrFailSound = speechFailBeepSwitch.isOn
    }
    
    @IBAction func logoutButtonDidClick(_ button: UIButton) {
        dismiss(animated: true, completion: {
            NuguCentralManager.shared.logout()
        })
    }
}
