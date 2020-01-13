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

import Foundation

public class NuguOAuthClient {
    /// <#Description#>
    public let deviceUniqueId: String
    
    /// <#Description#>
    /// - Parameter serviceName: <#serviceName description#>
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
    
    /// <#Description#>
    /// - Parameter deviceUniqueId: <#deviceUniqueId description#>
    public init(deviceUniqueId: String) {
        self.deviceUniqueId = deviceUniqueId
    }
}

// MARK: - AuthorizationCodeGrant

public extension NuguOAuthClient {
    /// <#Description#>
    /// - Parameter grant: <#grant description#>
    /// - Parameter parentViewController: <#parentViewController description#>
    /// - Parameter completion: <#completion description#>
    func authorize(grant: AuthorizationCodeGrant, parentViewController: UIViewController, completion: ((Result<AuthorizationInfo, Error>) -> Void)?) {
        grant.stateController.completionHandler = completion
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
            grant.stateController.completionHandler?(.failure(LoginError.invalidRequestURL))
            grant.stateController.clearState()
            return
        }
        
        // Complete function
        func complete(result: Result<AuthorizationInfo, Error>) {
            DispatchQueue.main.async {
                grant.stateController.dismissSafariViewController(completion: {
                    grant.stateController.completionHandler?(result)
                    grant.stateController.clearState()
                })
            }
        }
        
        grant.observer = NotificationCenter.default.addObserver(
            forName: .authorization,
            object: nil,
            queue: OperationQueue.main) { [weak self] (notification) in
                guard let self = self else {
                    complete(result: .failure(LoginError.unknown(description: "self is nil")))
                    return
                }
                
                guard let url = notification.userInfo?["url"] as? URL else {
                    complete(result: .failure(LoginError.invalidOpenURL))
                    return
                }
                
                // Get URLComponent
                guard let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    complete(result: .failure(LoginError.invalidOpenURL))
                    return
                }
                
                let scheme = urlComponent.scheme ?? ""
                let host = urlComponent.host ?? ""
                
                // Validate Redirect URI
                guard grant.redirectUri == "\(scheme)://\(host)" else {
                    complete(result: .failure(LoginError.invalidOpenURL))
                    return
                }
                
                // Get authorization code
                guard let authorizationCode = urlComponent.queryItems?.first(where: { $0.name == "code" })?.value else {
                    complete(result: .failure(LoginError.noAuthorizationCode))
                    return
                }
                
                // Validate state
                guard
                    let state = urlComponent.queryItems?.first(where: { $0.name == "state" })?.value,
                    state == grant.stateController.currentState else {
                        complete(result: .failure(LoginError.invalidState))
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
                    complete(result: result.mapError({ (error) -> Error in
                        return LoginError.network(error: error)
                    }))
                }
        }
        
        DispatchQueue.main.async {
            grant.stateController.presentSafariViewController(url: url, from: parentViewController)
        }
    }
    
    /// <#Description#>
    /// - Parameter url: <#url description#>
    class func handle(url: URL) {
         NotificationCenter.default.post(name: .authorization, object: nil, userInfo: ["url": url])
    }
}

// MARK: - RefreshTokenGrant

public extension NuguOAuthClient {
    /// <#Description#>
    /// - Parameter grant: <#grant description#>
    /// - Parameter completion: <#completion description#>
    func authorize(grant: RefreshTokenGrant, completion: ((Result<AuthorizationInfo, Error>) -> Void)?) {
        let api = NuguOAuthApi(
            clientId: grant.clientId,
            clientSecret: grant.clientSecret,
            deviceUniqueId: deviceUniqueId,
            grantTypeInfo: .refreshToken(refreshToken: grant.refreshToken)
        )
        
        api.request(completion: completion)
    }
}

// MARK: - ClientCredentialsGrant

public extension NuguOAuthClient {
    /// <#Description#>
    /// - Parameter grant: <#grant description#>
    /// - Parameter completion: <#completion description#>
    func authorize(grant: ClientCredentialsGrant, completion: ((Result<AuthorizationInfo, Error>) -> Void)?) {
        let api = NuguOAuthApi(
            clientId: grant.clientId,
            clientSecret: grant.clientSecret,
            deviceUniqueId: deviceUniqueId,
            grantTypeInfo: .clientCredentials
        )
        
        api.request(completion: completion)
    }
}

// MARK: - Notification.Name (for authorization-code grant)

private extension Notification.Name {
    static let authorization = Notification.Name(rawValue: "com.sktelecom.romaine.authorization")
}
