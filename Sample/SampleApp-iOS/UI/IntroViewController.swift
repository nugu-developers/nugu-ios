//
//  IntroViewController.swift
//  SampleApp-iOS
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
import NuguLoginKit

final class IntroViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet private weak var loginMethodLabel: UILabel!
    
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: Deinitialize
    
    deinit {}
}

// MARK: - IBAction

private extension IntroViewController {
    @IBAction func nuguAppLinkButtonDidClick(_ button: UIButton) {
        login()
    }
}

// MARK: - Private (Login)

private extension IntroViewController {
    func login() {
        switch SampleApp.loginMethod {
        case .type1?:
            guard let clientId = SampleApp.clientId,
                let clientSecret = SampleApp.clientSecret,
                let redirectUri = SampleApp.redirectUri else {
                    log.debug("clientId, clientSecret, redirectUri is nil")
                    return
            }

            OAuthManager<Type1>.shared.loginTypeInfo = Type1(
                clientId: clientId,
                clientSecret: clientSecret,
                redirectUri: redirectUri,
                deviceUniqueId: SampleApp.deviceUniqueId
            )
            
            switch UserDefaults.Standard.refreshToken {
            case .some(let refreshToken):
                loginSilently(refreshToken: refreshToken)
            case .none:
                loginType1()
            }
        case .type2?:
            guard let clientId = SampleApp.clientId,
                let clientSecret = SampleApp.clientSecret else {
                    log.debug("clientId, clientSecret, redirectUri is nil")
                    return
            }
            
            OAuthManager<Type2>.shared.loginTypeInfo = Type2(
                clientId: clientId,
                clientSecret: clientSecret,
                deviceUniqueId: SampleApp.deviceUniqueId
            )
            
            loginType2()
        default:
            // No mandatory data
            presentNoDataPopup()
        }
    }
}

// MARK: Private (Type1)

private extension IntroViewController {
    func loginSilently(refreshToken: String) {
        OAuthManager<Type1>.shared.loginSilently(by: refreshToken) { [weak self] (result) in
            switch result {
            case .success(let response):
                UserDefaults.Standard.accessToken = response.accessToken
                UserDefaults.Standard.refreshToken = response.refreshToken
                
                // Save login method (not necessary)
                UserDefaults.Standard.currentloginMethod = SampleApp.LoginMethod.type1.rawValue
                
                DispatchQueue.main.async { [weak self] in
                    self?.performSegue(withIdentifier: "introToMain", sender: nil)
                }
            case .failure(_):
                // TODO: - present popup when only invalid refreshToken issue
                self?.presentLoginType1ErrorPopup()
            }
        }
    }
    
    func loginType1() {
        OAuthManager<Type1>.shared.loginBySafariViewController(from: self) { (result) in
            switch result {
            case .success(let response):
                UserDefaults.Standard.accessToken = response.accessToken
                UserDefaults.Standard.refreshToken = response.refreshToken
                
                // Save login method (not necessary)
                UserDefaults.Standard.currentloginMethod = SampleApp.LoginMethod.type1.rawValue
                
                DispatchQueue.main.async { [weak self] in
                    self?.performSegue(withIdentifier: "introToMain", sender: nil)
                }
            case .failure(let error):
                log.info("failed to login with error: \(error)")
                break
            }
        }
    }
}

// MARK: Private (Type2)

private extension IntroViewController {
    func loginType2() {
        OAuthManager<Type2>.shared.login(completion: { (result) in
            switch result {
            case .success(let response):
                UserDefaults.Standard.accessToken = response.accessToken
                
               // Save login method (not necessary)
                UserDefaults.Standard.currentloginMethod = SampleApp.LoginMethod.type2.rawValue
                
                DispatchQueue.main.async { [weak self] in
                    self?.performSegue(withIdentifier: "introToMain", sender: nil)
                }
            case .failure(let error):
                log.info("failed to login with error: \(error)")
            }
        })
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
    
    func presentLoginType1ErrorPopup() {
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

