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

import NuguClientKit

final class SettingViewController: UIViewController {
    // MARK: - Properties
    
    @IBOutlet private weak var tableView: UITableView!

    private let settingMenu = [
        ["TID"],
        ["서비스 관리"],
        ["NUGU 사용하기", "이름을 불러 대화 시작하기", "부르는 이름", "호출 효과음", "응답 효과음", "응답 실패 효과음"],
        ["이용약관", "개인정보 처리방침"],
        ["연결 해제"]
    ]
    
    private var tid: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            }
        }
    }
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NuguCentralManager.shared.client.speechRecognizerAggregator.useKeywordDetector = false
        
        tableView.reloadData()
        
        updateTid()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nuguServiceWebViewController = segue.destination as? NuguServiceWebViewController,
            let initialURLString = sender as? String {
            nuguServiceWebViewController.initialURLString = initialURLString
        }
    }
    
    private func updateTid() {
        NuguCentralManager.shared.getUserInfo { [weak self] (result) in
            switch result {
            case .success(let nuguUserInfo):
                self?.tid = nuguUserInfo.username
            case .failure:
                self?.tid = nil
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension SettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingMenu.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingMenu[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell") as? SettingTableViewCell else {
            return UITableViewCell()
        }
        let menuTitle = settingMenu[indexPath.section][indexPath.row]
        let switchEnableability = (UserDefaults.Standard.useNuguService == true)
        
        if indexPath.section == 0 {
            cell.configure(text: menuTitle, detailText: tid)
        } else if indexPath.section == 2 {
            switch indexPath.row {
            case 0:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useNuguService, isSwitchEnabled: true)
                cell.onSwitchValueChanged = { [weak self] isOn in
                    UserDefaults.Standard.useNuguService = isOn
                    self?.tableView.reloadData()
                }
            case 1:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useWakeUpDetector, isSwitchEnabled: switchEnableability)
                cell.onSwitchValueChanged = { isOn in
                    UserDefaults.Standard.useWakeUpDetector = isOn
                }
            case 2:
                cell.configure(text: menuTitle, detailText: Keyword(rawValue: UserDefaults.Standard.wakeUpWord)?.description)
            case 3:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useAsrStartSound, isSwitchEnabled: switchEnableability)
                cell.onSwitchValueChanged = { isOn in
                    UserDefaults.Standard.useAsrStartSound = isOn
                }
            case 4:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useAsrSuccessSound, isSwitchEnabled: switchEnableability)
                cell.onSwitchValueChanged = { isOn in
                    UserDefaults.Standard.useAsrSuccessSound = isOn
                }
            case 5:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useAsrFailSound, isSwitchEnabled: switchEnableability)
                cell.onSwitchValueChanged = { isOn in
                    UserDefaults.Standard.useAsrFailSound = isOn
                }
            default:
                break
            }
        } else {
            cell.configure(text: menuTitle)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = (indexPath.section, indexPath.row)
        switch index {
        case (0, 0):
            NuguCentralManager.shared.showTidInfo(parentViewController: self) { [weak self] in
                self?.updateTid()
            }
        case (1, 0):
            ConfigurationStore.shared.serviceSettingUrl { [weak self] (result) in
                switch result {
                case .success(let urlString):
                    self?.performSegue(withIdentifier: "showNuguServiceWebView", sender: urlString)
                case .failure(let error):
                    log.error(error)
                }
            }
        case (2, 2):
            let wakeUpWordActionSheet = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .actionSheet
            )
            Keyword.allCases.forEach { [weak self] (keyword) in
                let action = UIAlertAction(
                    title: keyword.description,
                    style: .default) { [weak self] _ in
                        NuguCentralManager.shared.client.keywordDetector.keywordSource = keyword.keywordSource
                        UserDefaults.Standard.wakeUpWord = keyword.rawValue
                        self?.tableView.reloadData()
                }
                wakeUpWordActionSheet.addAction(action)
            }
            present(wakeUpWordActionSheet, animated: true)
        case (3, 0):
            ConfigurationStore.shared.agreementUrl { [weak self] (result) in
                switch result {
                case .success(let urlString):
                    self?.performSegue(withIdentifier: "showNuguServiceWebView", sender: urlString)
                case .failure(let error):
                    log.error(error)
                }
            }
        case (3, 1):
            ConfigurationStore.shared.privacyUrl { (result) in
                switch result {
                case .success(let urlString):
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                case .failure(let error):
                    log.error(error)
                }
            }
        case (4, 0):
            dismiss(animated: true, completion: {
                NuguCentralManager.shared.revoke()
            })
        default:
            break
        }
    }
}

// MARK: - Private (IBAction)

private extension SettingViewController {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        NuguCentralManager.shared.client.speechRecognizerAggregator.useKeywordDetector = UserDefaults.Standard.useWakeUpDetector
        dismiss(animated: true)
    }
}
