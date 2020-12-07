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
    var appStateObserver: Any?
    @IBOutlet private weak var loginMethodLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshView()
        
        if SampleApp.loginMethod == .type1 && UserDefaults.Standard.refreshToken != nil {
            logIn()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        appStateObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.refreshView()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let appStateObserver = appStateObserver {
            NotificationCenter.default.removeObserver(appStateObserver)
            self.appStateObserver = nil
        }
    }
}

// MARK: - Private (login)

private extension IntroViewController {
    func logIn() {
        guard SampleApp.loginMethod != nil else {
            presentNoDataPopup()
            return
        }

        NuguCentralManager.shared.login(from: self, completion: { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async { [weak self] in
                    self?.performSegue(withIdentifier: "introToMain", sender: nil)
                }
            case .failure(let sampleAppError):
                log.debug(sampleAppError.errorDescription)
                switch sampleAppError {
                case .loginWithRefreshTokenFailed:
                    self?.presentLoginWithRefreshTokenErrorPopup()
                case .loginFailed, .loginUnauthorized:
                    DispatchQueue.main.async {
                        NuguToast.shared.showToast(message: sampleAppError.errorDescription)
                    }
                default: break
                }
            }
        })
    }
}

// MARK: - IBAction

private extension IntroViewController {
    @IBAction func nuguLoginButtonDidClick(_ button: UIButton) {
        logIn()
    }
}

// MARK: - View

private extension IntroViewController {
    func refreshView() {
        if let name = SampleApp.loginMethod?.name {
            loginMethodLabel.text = "\(name) Mode"
        } else {
            loginMethodLabel.text = "샘플 데이터 없음"
        }
    }
    
    // MARK: AlertController
    
    func presentLoginWithRefreshTokenErrorPopup() {
        let alertController = UIAlertController(
            title: "Warning",
            message: "Try to login with refreshToken that saved in userdefaults, but refreshToken is invalid. If you want to clear saved data, click \"Confirm\".",
            preferredStyle: .alert
        )
        
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .destructive)
        )
        alertController.addAction(
            UIAlertAction(title: "Confirm", style: .default, handler: { (_) in
                UserDefaults.Standard.clear()
                UserDefaults.Nugu.clear()
            }
        ))
        DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true)
        }
    }
    
    func presentNoDataPopup() {
        let alertController = UIAlertController(
            title: "Warning",
            message: "App has not mandatory data, see SampleApp.swift",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true)
        }
    }
}

// MARK: - Private (Selector)

@objc private extension IntroViewController {
    func willEnterForeground(_ notification: Notification) {
        refreshView()
    }
}
