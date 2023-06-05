//
//  NuguServiceWebViewController.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/07/02.
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
import SafariServices

import NuguServiceKit
import NuguAgents

final class NuguServiceWebViewController: UIViewController {
    var initialURLString: String?
    
    // MARK: Properties
    
    @IBOutlet private weak var nuguServiceWebView: NuguServiceWebView!
    
    // MARK: Observers
    
    private var authObserver: Any?
    
    // MARK: Override
    
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
        
        NuguCentralManager.shared.client.routineAgent.delegate = self
        nuguServiceWebView.javascriptDelegate = self
        nuguServiceWebView.addCookie([
            NuguServiceCookieKey.theme.rawValue: NuguServiceCookieValue.Theme.light.rawValue,
            NuguServiceCookieKey.deviceUniqueId.rawValue: "put_your_own_device_unique_id_if_needed"
        ])
        nuguServiceWebView.loadUrlString(initialURLString)
        
        authObserver = NotificationCenter.default.addObserver(forName: .oauthRefreshNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.presentedViewController?.dismiss(animated: true, completion: nil)
            self?.nuguServiceWebView.reload()
        })
    }
    
    // MARK: Deinitialize
    
    deinit {
        if let authObserver = authObserver {
            NotificationCenter.default.removeObserver(authObserver)
            self.authObserver = nil
        }
    }
}

// MARK: - NuguServiceWebJavascriptDelegate

extension NuguServiceWebViewController: NuguServiceWebJavascriptDelegate {
    func openExternalApp(openExternalAppItem: WebOpenExternalApp) {
        log.debug("openExternalApp : \(openExternalAppItem)")
        if let appSchemeUrl = URL(string: openExternalAppItem.scheme ?? ""),
            UIApplication.shared.canOpenURL(appSchemeUrl) == true {
            UIApplication.shared.open(appSchemeUrl, options: [:], completionHandler: nil)
            return
        }
        if let appId = openExternalAppItem.appId,
            let appStoreUrl = URL(string: "https://itunes.apple.com/app/" + appId + "?mt=8"),
            UIApplication.shared.canOpenURL(appStoreUrl) == true {
            UIApplication.shared.open(appStoreUrl, options: [:], completionHandler: nil)
        }
    }
    
    func openInAppBrowser(url: String) {
        log.debug("openInAppBrowser : \(url)")
        present(SFSafariViewController(url: URL(string: url)!), animated: true, completion: nil)
    }
    
    func closeWindow(reason: String?) {
        log.debug("closeWindow : \(reason ?? "nil")")
        if reason == "WITHDRAWN_USER" {
            navigationController?.dismiss(animated: true, completion: {
                NuguCentralManager.shared.clearSampleApp()
            })
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func requestActiveRoutine() {
        guard let routineItem = NuguCentralManager.shared.client.routineAgent.routineItem,
              NuguCentralManager.shared.client.routineAgent.state == .playing else {
            return
        }
        nuguServiceWebView.onRoutineStatusChanged(token: routineItem.payload.token, status: RoutineState.playing.routineActivity)
    }
}

// MARK: - IBAction

private extension NuguServiceWebViewController {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

extension NuguServiceWebViewController: RoutineAgentDelegate {
    func routineAgentWillProcessAction(_ action: NuguAgents.RoutineItem.Payload.Action) {
        log.debug("routineAgentWillProcessAction, action: \(action)")
    }
    
    func routineAgentDidChange(state: RoutineState, item: RoutineItem?) {
        guard let token = item?.payload.token else { return }
        
        nuguServiceWebView.onRoutineStatusChanged(token: token, status: state.routineActivity)
    }
    
    func routineAgentDidStopProcessingAction(_ action: NuguAgents.RoutineItem.Payload.Action) {
        log.debug("routineAgentWillProcessAction, action: \(action)")
    }
    
    func routineAgentDidFinishProcessingAction(_ action: NuguAgents.RoutineItem.Payload.Action) {
        log.debug("routineAgentWillProcessAction, action: \(action)")
    }
}
