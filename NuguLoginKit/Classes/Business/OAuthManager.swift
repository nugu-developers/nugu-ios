//
//  OAuthManager.swift
//  NuguLoginKit
//
//  Created by yonghoonKwon on 11/09/2019.
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

/// `OAuthManager` provides methods for login to NUGU.
///
/// `OAuthManager` provides only methods for oauth authentication.
/// The `AuthorizationInfo` which is a response to oauth authentication, should be managed manually by the app.
public final class OAuthManager<T: LoginType> {
    
    /// The info for login with type. It is mandatory for any API.
    public var loginTypeInfo: T?
    
    private lazy var stateController = OAuthStateController() // for type1
    private let serverBaseUrl: String
    
    private init() {
        guard let url = Bundle.main.url(forResource: "Nugu-Info", withExtension: "plist") else {
            serverBaseUrl = defaultServerBaseUrl
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let configuration = try PropertyListDecoder().decode(NuguLoginConfiguration.self, from: data)
            serverBaseUrl = configuration.serverBaseUrl
        } catch {
            serverBaseUrl = defaultServerBaseUrl
        }
    }
}

// MARK: - Singleton for type1

public extension OAuthManager where T == Type1 {
    /// The singleton instance for Type1.
    static var shared: OAuthManager<T> = {
        return OAuthManager<T>()
    }()
}

// MARK: - API for type1

public extension OAuthManager where T: Type1 {
    /// Request NUGU login by SFSafariViewController.
    ///
    /// Request OAuth 2.0 by authorization code grant type.
    ///
    /// - Parameter parentViewController: The viewcontroller will present a safariViewController.
    /// - Parameter completion: The closure to receive result for NUGU login.
    func loginBySafariViewController(
        from parentViewController: UIViewController,
        completion: ((Result<AuthorizationInfo, Error>) -> Void)? = nil
        ) {
        guard let loginTypeInfo = loginTypeInfo else {
            completion?(.failure(LoginError.noLoginTypeInfo))
            return
        }
        
        stateController.completionHandler = completion
        let state = stateController.makeState()
        
        var urlComponents = URLComponents(string: serverBaseUrl + "/oauth/authorize")
        
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "response_type", value: "code"))
        queries.append(URLQueryItem(name: "state", value: state))
        queries.append(URLQueryItem(name: "client_id", value: loginTypeInfo.clientId))
        queries.append(URLQueryItem(name: "redirect_uri", value: loginTypeInfo.redirectUri))
        
        if let deviceUniqueId = loginTypeInfo.deviceUniqueId {
            queries.append(URLQueryItem(name: "data", value: "{\"deviceSerialNumber\":\"\(deviceUniqueId)\"}"))
        }
        
        urlComponents?.queryItems = queries
        
        guard let url = urlComponents?.url else {
            stateController.completionHandler?(.failure(LoginError.invalidRequestURL))
            stateController.clearState()
            return
        }
        
        DispatchQueue.main.async {
            self.stateController.presentSafariViewController(url: url, from: parentViewController)
        }
    }
    
    /// Call this method from the `UIApplicationDelegate.application(app:url:options:)` method of the AppDelegate for your app.
    ///
    /// It should be implemeted to receive authorization-code by SFSafariViewController.
    /// It validates `state` and `redirectURI` internally.
    ///
    /// - Parameter url: The URL as passed to `UIApplicationDelegate.application(app:url:options:)`.
    /// - Parameter options: Thr options as passed to `UIApplicationDelegate.application(app:url:options:)`.
    func handle(open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let loginTypeInfo = loginTypeInfo else {
            return false
        }
        
        // Complete function
        func complete(result: Result<AuthorizationInfo, Error>) {
            DispatchQueue.main.async {
                self.stateController.dismissSafariViewController(completion: {
                    self.stateController.completionHandler?(result)
                    self.stateController.clearState()
                })
            }
        }
        
        // Get URLComponent
        guard let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            complete(result: .failure(LoginError.invalidOpenURL))
            return false
        }
        
        let scheme = urlComponent.scheme ?? ""
        let host = urlComponent.host ?? ""
        
        // Validate Redirect URI
        guard loginTypeInfo.redirectUri == "\(scheme)://\(host)" else {
            complete(result: .failure(LoginError.invalidOpenURL))
            return false
        }
        
        // Get authorization code
        guard let authorizationCode = urlComponent.queryItems?.first(where: { $0.name == "code" })?.value else {
            complete(result: .failure(LoginError.noAuthorizationCode))
            return false
        }
        
        // Validate state
        guard
            let state = urlComponent.queryItems?.first(where: { $0.name == "state" })?.value,
            state == stateController.currentState else {
                complete(result: .failure(LoginError.invalidState))
                return false
        }
        
        // Acquire token
        Type1Api().acquireToken(
            serverBaseUrl: serverBaseUrl,
            code: authorizationCode,
            redirectUri: loginTypeInfo.redirectUri,
            clientId: loginTypeInfo.clientId,
            clientSecret: loginTypeInfo.clientSecret) { (result) in
                complete(result: result.mapError({ (error) -> Error in
                    return LoginError.network(error: error)
                }))
        }
        
        return true
    }
    
    /// Request NUGU login silently.
    ///
    /// Request OAuth 2.0 by refresh token grant type.
    /// Request Nugu login without any UI. If has refresh-token, can refresh authorization-info.
    /// It occurs error when the refresh-token expires.
    /// - Parameter refreshToken: The token to refresh authorization-info.
    /// - Parameter completion: The closure to receive result for NUGU login.
    func loginSilently(
        by refreshToken: String,
        completion: ((Result<AuthorizationInfo, Error>) -> Void)? = nil
        ) {
        guard let loginTypeInfo = loginTypeInfo else {
            completion?(.failure(LoginError.noLoginTypeInfo))
            return
        }
        
        Type1Api().refreshToken(
            serverBaseUrl: serverBaseUrl,
            refreshToken: refreshToken,
            clientId: loginTypeInfo.clientId,
            clientSecret: loginTypeInfo.clientSecret) { (result) in
                completion?(result.mapError({ (error) -> Error in
                    return LoginError.network(error: error)
                }))
        }
    }
}

// MARK: - Singleton for type2

public extension OAuthManager where T == Type2 {
    /// The singleton instance for Type2
    static var shared: OAuthManager<T> = {
        return OAuthManager<T>()
    }()
}

// MARK: - API for type2

public extension OAuthManager where T: Type2 {
    /// Request NUGU login.
    ///
    /// Request OAuth 2.0 by client credentials grant type.
    ///
    /// - Parameter completion: The closure to receive result for NUGU login.
    func login(completion: ((Result<AuthorizationInfo, Error>) -> Void)? = nil) {
        guard let loginTypeInfo = loginTypeInfo else {
            completion?(.failure(LoginError.noLoginTypeInfo))
            return
        }
        
        Type2Api().getToken(
            serverBaseUrl: serverBaseUrl,
            clientId: loginTypeInfo.clientId,
            clientSecret: loginTypeInfo.clientSecret,
            deviceSerialNumber: loginTypeInfo.deviceUniqueId) { (result) in
                completion?(result.mapError({ (error) -> Error in
                    return LoginError.network(error: error)
                }))
        }
    }
}
