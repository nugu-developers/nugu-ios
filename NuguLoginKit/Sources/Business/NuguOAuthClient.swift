//
//  NuguOAuthClient.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 2019/12/21.
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

public class NuguOAuthClient {
    /// The `deviceUniqueId` is unique identifier each device.
    public let deviceUniqueId: String
    
    private var observer: NSObjectProtocol?
    
    /// The initializer for `NuguOAuthClient`.
    /// Create a `deviceUniqueId` once for each `serviceName` and device, store `deviceUniqueId` in keychain.
    /// If there is a `deviceUniqueId` stored in the keychain, it is used.
    /// - Parameter serviceName: The `serviceName` is unique identifier each service (eg. bundle identifier).
    public convenience init(serviceName: String) throws {
        let keychainHelper = KeychainHelper(service: serviceName)
        guard let deviceUniqueId = try? keychainHelper.string(forKey: "deviceUniqueId") else {
            let uuid = UUID().uuidString
            try keychainHelper.setValue(uuid, forKey: "deviceUniqueId")
            
            self.init(deviceUniqueId: uuid)
            return
        }
        
        self.init(deviceUniqueId: deviceUniqueId)
    }
    
    /// The initializer for `NuguOAuthClient`.
    /// Should be use `init(serviceName: String)` instead of `init(deviceUniqueId: String)`.
    /// Only use `init(deviceUniqueId: String)` when it must explicitly used `deviceUniqueId`.
    /// It cannot store and validate `deviceUniqueId`.
    /// - Parameter deviceUniqueId: The `deviceUniqueId` is unique identifier each device.
    public init(deviceUniqueId: String) {
        self.deviceUniqueId = deviceUniqueId
    }
    
    deinit {
        observer = nil
    }
}

// MARK: - AuthorizationCodeGrant

public extension NuguOAuthClient {
    /// Authorize with `AuthorizationCode` grant type.
    /// - Parameter grant: The `grant` information that `AuthorizationCodeGrant`
    /// - Parameter parentViewController: The `parentViewController` will present a safariViewController.
    /// - Parameter completion: The closure to receive result for authorization.
    func authorize(grant: AuthorizationCodeGrant, parentViewController: UIViewController, completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?) {
        grant.stateController.completion = completion
        let state = grant.stateController.makeState()
        var urlComponents = URLComponents(string: NuguOAuthServerInfo.serverBaseUrl + "/oauth/authorize")
        
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "response_type", value: "code"))
        queries.append(URLQueryItem(name: "state", value: state))
        queries.append(URLQueryItem(name: "client_id", value: grant.clientId))
        queries.append(URLQueryItem(name: "redirect_uri", value: grant.redirectUri))
        queries.append(URLQueryItem(name: "data", value: "{\"deviceSerialNumber\":\"\(deviceUniqueId)\"}"))
        
        urlComponents?.queryItems = queries
        
        guard let url = urlComponents?.url else {
            grant.stateController.completion?(.failure(NuguLoginKitError.invalidRequestURL))
            grant.stateController.clearState()
            return
        }
        
        // Complete function
        func complete(result: Result<AuthorizationInfo, NuguLoginKitError>) {
            DispatchQueue.main.async {
                grant.stateController.dismissSafariViewController(completion: {
                    grant.stateController.completion?(result)
                    grant.stateController.clearState()
                })
            }
        }
        
        observer = NotificationCenter.default.addObserver(
            forName: .authorization,
            object: nil,
            queue: OperationQueue.main) { [weak self] (notification) in
                guard let self = self else {
                    complete(result: .failure(NuguLoginKitError.unknown(description: "self is nil")))
                    return
                }
                
                guard let url = notification.userInfo?["url"] as? URL else {
                    complete(result: .failure(NuguLoginKitError.invalidOpenURL))
                    return
                }
                
                // Get URLComponent
                guard let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    complete(result: .failure(NuguLoginKitError.invalidOpenURL))
                    return
                }
                
                let scheme = urlComponent.scheme ?? ""
                let host = urlComponent.host ?? ""
                
                // Validate Redirect URI
                guard grant.redirectUri == "\(scheme)://\(host)" else {
                    complete(result: .failure(NuguLoginKitError.invalidOpenURL))
                    return
                }
                
                // Get authorization code
                guard let authorizationCode = urlComponent.queryItems?.first(where: { $0.name == "code" })?.value else {
                    complete(result: .failure(NuguLoginKitError.noAuthorizationCode))
                    return
                }
                
                // Validate state
                guard
                    let state = urlComponent.queryItems?.first(where: { $0.name == "state" })?.value,
                    state == grant.stateController.currentState else {
                        complete(result: .failure(NuguLoginKitError.invalidState))
                        return
                }
                
                // Acquire token
                let api = NuguOAuthApi(
                    clientId: grant.clientId,
                    clientSecret: grant.clientSecret,
                    deviceUniqueId: self.deviceUniqueId,
                    grantTypeInfo: .authorizationCode(code: authorizationCode, redirectUri: grant.redirectUri)
                )
                
                api.request { (result) in
                    complete(result: result.mapError({ NuguLoginKitError.apiError(error: $0) }))
                }
        }
        
        DispatchQueue.main.async {
            grant.stateController.presentSafariViewController(url: url, from: parentViewController)
        }
    }
    
    /// Call this method from the `UIApplicationDelegate.application(app:url:options:)` method of the AppDelegate for your app.
    ///
    /// It should be implemeted to receive authorization-code by `SFSafariViewController`.
    ///
    /// - Parameter url: The URL as passed to `UIApplicationDelegate.application(app:url:options:)`.
    class func handle(url: URL) {
         NotificationCenter.default.post(name: .authorization, object: nil, userInfo: ["url": url])
    }
}

// MARK: - RefreshTokenGrant

public extension NuguOAuthClient {
    /// Authorize with `RefreshToken` grant type.
    /// - Parameter grant: The `grant` information that `RefreshTokenGrant`
    /// - Parameter completion: The closure to receive result for authorization.
    func authorize(grant: RefreshTokenGrant, completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?) {
        let api = NuguOAuthApi(
            clientId: grant.clientId,
            clientSecret: grant.clientSecret,
            deviceUniqueId: deviceUniqueId,
            grantTypeInfo: .refreshToken(refreshToken: grant.refreshToken)
        )
        
        api.request { (result) in
            completion?(result.mapError({ NuguLoginKitError.apiError(error: $0) }))
        }
    }
}

// MARK: - ClientCredentialsGrant

public extension NuguOAuthClient {
    /// Authorize with `ClientCredentials` grant type.
    /// - Parameter grant: The `grant` information that `ClientCredentialsGrant`
    /// - Parameter completion: The closure to receive result for authorization.
    func authorize(grant: ClientCredentialsGrant, completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?) {
        let api = NuguOAuthApi(
            clientId: grant.clientId,
            clientSecret: grant.clientSecret,
            deviceUniqueId: deviceUniqueId,
            grantTypeInfo: .clientCredentials
        )
        
        api.request { (result) in
            completion?(result.mapError({ NuguLoginKitError.apiError(error: $0) }))
        }
    }
}

// MARK: - Notification.Name (for authorization-code grant)

private extension Notification.Name {
    static let authorization = Notification.Name(rawValue: "com.sktelecom.romaine.authorization")
}
