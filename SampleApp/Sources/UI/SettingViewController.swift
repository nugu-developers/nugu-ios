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
        ["테마 설정"],
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard UserDefaults.Standard.theme == SampleApp.Theme.system.rawValue else { return }
        NuguCentralManager.shared.themeController.theme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch NuguCentralManager.shared.themeController.theme {
        case .dark:
            return .lightContent
        case .light:
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                return .default
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            case .failure(let nuguLoginKitError):
                let sampleAppError = SampleAppError.parseFromNuguLoginKitError(error: nuguLoginKitError)
                if case SampleAppError.loginUnauthorized = sampleAppError {
                    DispatchQueue.main.async { [weak self] in
                        self?.dismiss(animated: true)
                    }
                } else {
                    self?.tid = nil
                }
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
        } else if indexPath.section == 3 {
            switch indexPath.row {
            case 0:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useNuguService)
                cell.onSwitchValueChanged = { [weak self] isOn in
                    UserDefaults.Standard.useNuguService = isOn
                    self?.tableView.reloadData()
                }
            case 1:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useWakeUpDetector)
                cell.onSwitchValueChanged = { [weak self] isOn in
                    NuguCentralManager.shared.client.speechRecognizerAggregator.useKeywordDetector = isOn
                    UserDefaults.Standard.useWakeUpDetector = isOn
                    self?.tableView.reloadData()
                }
                cell.isEnabled = switchEnableability
            case 2:
                let description = UserDefaults.Standard.wakeUpWordDictionary["description"]
                cell.configure(text: menuTitle, detailText: description)
                cell.isEnabled = switchEnableability && UserDefaults.Standard.useWakeUpDetector
            case 3:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useAsrStartSound)
                cell.onSwitchValueChanged = { isOn in
                    UserDefaults.Standard.useAsrStartSound = isOn
                }
                cell.isEnabled = switchEnableability
            case 4:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useAsrSuccessSound)
                cell.onSwitchValueChanged = { isOn in
                    UserDefaults.Standard.useAsrSuccessSound = isOn
                }
                cell.isEnabled = switchEnableability
            case 5:
                cell.configure(text: menuTitle, isSwitchOn: UserDefaults.Standard.useAsrFailSound)
                cell.onSwitchValueChanged = { isOn in
                    UserDefaults.Standard.useAsrFailSound = isOn
                }
                cell.isEnabled = switchEnableability
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
            let themeActionSheet = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .actionSheet
            )
            SampleApp.Theme.allCases.forEach { [weak self] (theme) in
                let action = UIAlertAction(
                    title: theme.name,
                    style: .default) { [weak self] _ in
                    switch theme {
                    case .system:
                        NuguCentralManager.shared.themeController.theme = self?.traitCollection.userInterfaceStyle == .dark ? .dark : .light
                    case .light:
                        NuguCentralManager.shared.themeController.theme = .light
                    case .dark:
                        NuguCentralManager.shared.themeController.theme = .dark
                    }
                    UserDefaults.Standard.theme = theme.rawValue
                    self?.setNeedsStatusBarAppearanceUpdate()
                }
                themeActionSheet.addAction(action)
            }
            if UIDevice.current.userInterfaceIdiom == .phone {
                present(themeActionSheet, animated: true)
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                if let popoverController = themeActionSheet.popoverPresentationController {
                    popoverController.sourceView = view
                    present(themeActionSheet, animated: true, completion: nil)
                }
            }
        case (2, 0):
            ConfigurationStore.shared.serviceSettingUrl { [weak self] (result) in
                switch result {
                case .success(let urlString):
                    DispatchQueue.main.async { [weak self] in
                        self?.performSegue(withIdentifier: "showNuguServiceWebView", sender: urlString)
                    }
                case .failure(let error):
                    log.error(error)
                }
            }
        case (3, 2):
            let wakeUpWordActionSheet = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .actionSheet
            )
            Keyword.allCases.forEach { [weak self] (keyword) in
                let action = UIAlertAction(
                    title: keyword.description,
                    style: .default) { [weak self] _ in
                        NuguCentralManager.shared.client.keywordDetector.keyword = keyword
                        UserDefaults.Standard.wakeUpWordDictionary = [
                            "rawValue": String(keyword.rawValue),
                            "description": keyword.description
                        ]
                        self?.tableView.reloadData()
                }
                wakeUpWordActionSheet.addAction(action)
            }
            
            let customAction = UIAlertAction(
                title: "Custom",
                style: .default) { [weak self] _ in
                    let alert = UIAlertController(
                        title: "Custom",
                        message: "Set a custom description, netFilePath, searchFilePath",
                        preferredStyle: .alert
                    )
                    alert.addTextField()
                    alert.addTextField()
                    alert.addTextField()
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .default)
                    let addAction = UIAlertAction(
                        title: "Add",
                        style: .default,
                        handler: { [weak self] _ in
                            let description = alert.textFields?[0].text ?? ""
                            let netFileName = alert.textFields?[1].text ?? ""
                            let searchFileName = alert.textFields?[2].text ?? ""
                        
                            NuguCentralManager.shared.client.keywordDetector.keyword =  .custom(
                                description: description,
                                netFilePath: Bundle.main.url(forResource: netFileName, withExtension: "raw")!.path,
                                searchFilePath:
                                    Bundle.main.url(forResource: searchFileName, withExtension: "raw")!.path
                            )
                            
                            UserDefaults.Standard.wakeUpWordDictionary = [
                                "rawValue": String(-1),
                                "description": description,
                                "netFileName": netFileName,
                                "searchFileName": searchFileName
                            ]
                            
                            self?.tableView.reloadData()
                    })
                    alert.addAction(cancelAction)
                    alert.addAction(addAction)
                    
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        self?.present(alert, animated: true)
                    } else if UIDevice.current.userInterfaceIdiom == .pad {
                        if let popoverController = alert.popoverPresentationController {
                            popoverController.sourceView = self?.view
                            self?.present(alert, animated: true, completion: nil)
                        }
                    }
            }
            wakeUpWordActionSheet.addAction(customAction)
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                present(wakeUpWordActionSheet, animated: true)
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                if let popoverController = wakeUpWordActionSheet.popoverPresentationController {
                    popoverController.sourceView = view
                    present(wakeUpWordActionSheet, animated: true, completion: nil)
                }
            }
        case (4, 0):
            ConfigurationStore.shared.agreementUrl { [weak self] (result) in
                switch result {
                case .success(let urlString):
                    self?.performSegue(withIdentifier: "showNuguServiceWebView", sender: urlString)
                case .failure(let error):
                    log.error(error)
                }
            }
        case (4, 1):
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
        case (5, 0):
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
