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
import SafariServices

import NuguUtils

/// <#Description#>
public class NuguOAuthClient {
    /// The `deviceUniqueId` is unique identifier each device.
    private(set) public var deviceUniqueId: String
    private var observer: Any?
    private var serviceName: String?
    private var oauthHandler: OAuthHandler {
        if let handler = _oauthHandler {
            return handler
        }
        
        _oauthHandler = ASAuthenticationOAuthHandler()
        
        return _oauthHandler!
    }
    
    private var _oauthHandler: OAuthHandler?
    
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
        self.serviceName = serviceName
    }
    
    /// The initializer for `NuguOAuthClient`.
    /// Should be use `init(serviceName: String)` instead of `init(deviceUniqueId: String)`.
    /// Only use `init(deviceUniqueId: String)` when it must explicitly used `deviceUniqueId`.
    /// It cannot store and validate `deviceUniqueId`.
    /// - Parameter deviceUniqueId: The `deviceUniqueId` is unique identifier each device.
    public init(deviceUniqueId: String) {
        self.deviceUniqueId = deviceUniqueId
    }
    
    /// Use to change the `deviceUniqueId`.
    ///
    /// - Parameter deviceUniqueId: The `deviceUniqueId` is unique identifier each device.
    public func update(deviceUniqueId: String) {
        self.deviceUniqueId = deviceUniqueId
        
        guard let serviceName = self.serviceName else {
            return
        }
        
        let keychainHelper = KeychainHelper(service: serviceName)
        do {
            try keychainHelper.setValue(deviceUniqueId, forKey: "deviceUniqueId")
        } catch {
            NSLog("Failed to store updated deviceUniqueId")
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        
        oauthHandler.clear()
        _oauthHandler = nil
    }
}

// MARK: - AuthorizationCodeGrant

public extension NuguOAuthClient {
    /// Call this method from the `UIApplicationDelegate.application(app:url:options:)` method of the AppDelegate for your app.
    ///
    /// It should be implemeted to receive authorization-code by `SFSafariViewController`.
    ///
    /// - Parameter url: The URL as passed to `UIApplicationDelegate.application(app:url:options:)`.
    class func handle(url: URL) {
         NotificationCenter.default.post(name: .authorization, object: nil, userInfo: ["url": url])
    }
    
    /// Authorize with `AuthorizationCode` grant type.
    /// - Parameter grant: The `grant` information that `AuthorizationCodeGrant`
    /// - Parameter parentViewController: The `parentViewController` will present a safariViewController.
    /// - Parameter completion: The closure to receive result for authorization.
    func authorize(
        grant: AuthorizationCodeGrant,
        parentViewController: UIViewController,
        additionalQueries: [URLQueryItem]? = nil,
        theme: WebTheme = .light,
        completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?
    ) {
        presentAuthorize(
            grant: grant,
            parentViewController: parentViewController,
            additionalQueries: additionalQueries,
            theme: theme,
            completion: completion
        )
    }
    
    /// Shows web-page where TID information can be modified with `AuthorizationCode` grant type.
    /// - Parameters:
    ///   - grant: The `grant` information that `AuthorizationCodeGrant`
    ///   - token: The `token` is access-token currently being used.
    ///   - parentViewController: The `parentViewController` will present a safariViewController.
    ///   - completion: The closure to receive result for authorization.
    func showTidInfo(
        grant: AuthorizationCodeGrant,
        token: String,
        parentViewController: UIViewController,
        theme: WebTheme = .light,
        completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?
    ) {
        var queries = [URLQueryItem]()
        queries.append(URLQueryItem(name: "prompt", value: "mypage"))
        queries.append(URLQueryItem(name: "access_token", value: token))
        
        presentAuthorize(grant: grant, parentViewController: parentViewController, additionalQueries: queries, theme: theme, completion: completion)
    }
    
    /// Get some NUGU member information.
    /// - Parameters:
    ///   - clientId: The `clientId` for OAuth authentication.
    ///   - clientSecret: The `clientSecret` for OAuth authentication.
    ///   - token: The `token` is access-token currently being used.
    ///   - completion: The closure to receive result for getting NUGU member information.
    func getUserInfo(
        clientId: String,
        clientSecret: String,
        token: String,
        completion: ((Result<NuguUserInfo, NuguLoginKitError>) -> Void)?
    ) {
        let api = NuguOAuthUtilApi(
            token: token,
            clientId: clientId,
            clientSecret: clientSecret,
            deviceUniqueId: deviceUniqueId,
            typeInfo: .getUserInfo
        )
        
        api.request { (result) in
            completion?(result
                .flatMap({ (data) -> Result<NuguUserInfo, NuguLoginKitError.APIError> in
                    guard let userInfo = try? JSONDecoder().decode(NuguUserInfo.self, from: data) else {
                        return .failure(.parsingFailed(data))
                    }
                    return .success(userInfo)
                })
                .mapError({ NuguLoginKitError.apiError(error: $0) })
            )
        }
    }
    
    /// Authorize with `AuthorizationCode` grant type without browser.
    /// - Parameters:
    ///   - grant: The `grant` information that `AuthorizationCodeGrant`
    ///   - authorizationCode: code for authorization.
    ///   - completion: The closure to receive result for authorization.
    func authorize(
        grant: AuthorizationCodeGrant,
        authorizationCode: String,
        completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?
    ) {
        // Acquire token
        let api = NuguOAuthTokenApi(
            clientId: grant.clientId,
            clientSecret: grant.clientSecret,
            deviceUniqueId: self.deviceUniqueId,
            grantTypeInfo: .authorizationCode(
                code: authorizationCode,
                redirectUri: grant.redirectUri
            )
        )
        
        api.request { (result) in
            completion?(result
                .flatMap({ (data) -> Result<AuthorizationInfo, NuguLoginKitError.APIError> in
                    guard let authorizationInfo = try? JSONDecoder().decode(AuthorizationInfo.self, from: data) else {
                        return .failure(.parsingFailed(data))
                    }
                    return .success(authorizationInfo)
                })
                .mapError({ NuguLoginKitError.apiError(error: $0) })
            )
        }
    }
}

// MARK: - RefreshTokenGrant

public extension NuguOAuthClient {
    /// Authorize with `RefreshToken` grant type.
    /// - Parameter grant: The `grant` information that `RefreshTokenGrant`
    /// - Parameter completion: The closure to receive result for authorization.
    func authorize(grant: RefreshTokenGrant, completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?) {
        let api = NuguOAuthTokenApi(
            clientId: grant.clientId,
            clientSecret: grant.clientSecret,
            deviceUniqueId: deviceUniqueId,
            grantTypeInfo: .refreshToken(refreshToken: grant.refreshToken)
        )
        
        api.request { (result) in
            completion?(result
                .flatMap({ (data) -> Result<AuthorizationInfo, NuguLoginKitError.APIError> in
                    guard let authorizationInfo = try? JSONDecoder().decode(AuthorizationInfo.self, from: data) else {
                        return .failure(.parsingFailed(data))
                    }
                    return .success(authorizationInfo)
                })
                .mapError({ NuguLoginKitError.apiError(error: $0) })
            )
        }
    }
}

// MARK: - ClientCredentialsGrant

public extension NuguOAuthClient {
    /// Authorize with `ClientCredentials` grant type.
    /// - Parameter grant: The `grant` information that `ClientCredentialsGrant`
    /// - Parameter completion: The closure to receive result for authorization.
    func authorize(grant: ClientCredentialsGrant, completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?) {
        let api = NuguOAuthTokenApi(
            clientId: grant.clientId,
            clientSecret: grant.clientSecret,
            deviceUniqueId: deviceUniqueId,
            grantTypeInfo: .clientCredentials
        )
        
        api.request { (result) in
            completion?(result
                .flatMap({ (data) -> Result<AuthorizationInfo, NuguLoginKitError.APIError> in
                    guard let authorizationInfo = try? JSONDecoder().decode(AuthorizationInfo.self, from: data) else {
                        return .failure(.parsingFailed(data))
                    }
                    return .success(authorizationInfo)
                })
                .mapError({ NuguLoginKitError.apiError(error: $0) })
            )
        }
    }
}

// MARK: - Util API

public extension NuguOAuthClient {
    /// Revoke completly with NUGU
    /// - Parameters:
    ///   - clientId: The `clientId` for OAuth authentication.
    ///   - clientSecret: The `clientSecret` for OAuth authentication.
    ///   - token: The `token` is access-token currently being used.
    ///   - completion: The closure to receive result for `revoke`.
    func revoke(clientId: String, clientSecret: String, token: String, completion: ((EndedUp<NuguLoginKitError>) -> Void)?) {
        let api = NuguOAuthUtilApi(
            token: token,
            clientId: clientId,
            clientSecret: clientSecret,
            deviceUniqueId: deviceUniqueId,
            typeInfo: .revoke
        )
        
        api.request { (result) in
            completion?(
                result
                    .flatMap { (_) -> Result<Void, NuguLoginKitError.APIError> in
                        return .success(())
                    }
                    .mapError { NuguLoginKitError.apiError(error: $0) }
                    .toEndedUp()
            )
        }
    }
    
    func cancel() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        
        oauthHandler.clear()
        _oauthHandler = nil
    }
}

// MARK: - Private

private extension NuguOAuthClient {
    func presentAuthorize(
        grant: AuthorizationCodeGrant,
        parentViewController: UIViewController,
        additionalQueries: [URLQueryItem]? = nil,
        theme: WebTheme = .light,
        completion: ((Result<AuthorizationInfo, NuguLoginKitError>) -> Void)?
    ) {
        let state = oauthHandler.makeState()
        var urlComponents = URLComponents(string: NuguOAuthServerInfo.serverBaseUrl + "/v1/auth/oauth/authorize")
        
        var queries = [URLQueryItem]() 
        queries.append(URLQueryItem(name: "response_type", value: "code"))
        queries.append(URLQueryItem(name: "state", value: state))
        queries.append(URLQueryItem(name: "client_id", value: grant.clientId))
        queries.append(URLQueryItem(name: "redirect_uri", value: grant.redirectUri))
        queries.append(URLQueryItem(name: "data", value: "{\"deviceSerialNumber\":\"\(deviceUniqueId)\", \"theme\":\"\(theme.rawValue)\"}"))
        
        if let additionalQueries = additionalQueries {
            queries.append(contentsOf: additionalQueries)
        }
        
        urlComponents?.queryItems = queries
        
        guard let url = urlComponents?.url else {
            completion?(.failure(NuguLoginKitError.invalidRequestURL))
            oauthHandler.clear()
            _oauthHandler = nil
            return
        }
        
        // Complete function
        func complete(result: Result<AuthorizationInfo, NuguLoginKitError>) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.oauthHandler.clear()
                self._oauthHandler = nil
                completion?(result)
                NotificationCenter.default.removeObserver(self.observer as Any)
                self.observer = nil
            }
        }
        
        observer = NotificationCenter.default.addObserver(
            forName: .authorization,
            object: nil,
            queue: .main) { [weak self] (notification) in
            guard let self = self else {
                complete(result: .failure(NuguLoginKitError.unknown(description: "self is nil")))
                return
            }
            
            switch notification.userInfo?["error"] {
            case let loginKitError as NuguLoginKitError:
                complete(result: .failure(loginKitError))
                return
            case let unknownError as Error:
                complete(result: .failure(NuguLoginKitError.unknown(description: unknownError.localizedDescription)))
                return
            default:
                break
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
                state == self.oauthHandler.currentState else {
                complete(result: .failure(NuguLoginKitError.invalidState))
                return
            }
            
            // Acquire token
            let api = NuguOAuthTokenApi(
                clientId: grant.clientId,
                clientSecret: grant.clientSecret,
                deviceUniqueId: self.deviceUniqueId,
                grantTypeInfo: .authorizationCode(code: authorizationCode, redirectUri: grant.redirectUri)
            )
            
            api.request { (result) in
                complete(result: result.flatMap({ (data) -> Result<AuthorizationInfo, NuguLoginKitError.APIError> in
                    guard let authorizationInfo = try? JSONDecoder().decode(AuthorizationInfo.self, from: data) else {
                        return .failure(.parsingFailed(data))
                    }
                    return .success(authorizationInfo)
                })
                .mapError({ NuguLoginKitError.apiError(error: $0) })
                )
            }
        }
            
        let redirectURLComponents = URLComponents(string: grant.redirectUri)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.oauthHandler.handle(url, callbackURLScheme: redirectURLComponents?.scheme, from: parentViewController)
        }
    }
}

// MARK: - Notification.Name (for authorization-code grant)

extension Notification.Name {
    static let authorization = Notification.Name(rawValue: "com.sktelecom.romaine.authorization")
}
