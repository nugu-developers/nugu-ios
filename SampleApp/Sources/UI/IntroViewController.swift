//
//  IntroViewController.swift
//  SampleApp
//
//  Created by yonghoonKwon on 01/07/2019.
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

import NuguUIKit

final class IntroViewController: UIViewController {
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SampleApp.loginMethod != nil {
            NuguCentralManager.shared.refreshToken { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .success:
                        self?.performSegue(withIdentifier: "introToMain", sender: nil)
                    case .failure(let sampleAppError):
                        log.debug(sampleAppError.errorDescription)
                        
                        NuguToast.shared.showToast(message: sampleAppError.errorDescription)
                        UserDefaults.Standard.clear()
                        UserDefaults.Nugu.clear()
                    }
                }
            }
        }
    }
}

// MARK: - Private (login)

private extension IntroViewController {
    func logIn() {
        NuguCentralManager.shared.login(from: self) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success:
                    self?.performSegue(withIdentifier: "introToMain", sender: nil)
                case .failure(let sampleAppError):
                    log.debug(sampleAppError.errorDescription)
                    
                    NuguToast.shared.showToast(message: sampleAppError.errorDescription)
                    UserDefaults.Standard.clear()
                    UserDefaults.Nugu.clear()
                }
            }
        }
    }
}

// MARK: - IBAction

private extension IntroViewController {
    @IBAction func tidLoginButtonDidClick(_ button: UIButton) {
        UserDefaults.Standard.loginMethod = SampleApp.LoginMethod.tid.rawValue
        logIn()
    }
    
    @IBAction func anonymousLoginButtonDidClick(_ button: UIButton) {
        UserDefaults.Standard.loginMethod = SampleApp.LoginMethod.anonymous.rawValue
        logIn()
    }
}
