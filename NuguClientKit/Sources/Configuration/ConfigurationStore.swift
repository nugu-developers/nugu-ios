//
//  ConfigurationStore.swift
//  NuguClientKit
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/11/13.
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

import NuguLoginKit

public class ConfigurationStore {
    public var configuration: Configuration? {
        didSet {
            guard let configuration = configuration else { return }
            
            NuguOAuthServerInfo.serverBaseUrl = configuration.authServerUrl
        }
    }
    public static let shared = ConfigurationStore()
    
    // singleton
    private init() {
    }
    
    public func configure(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public func configure(url: URL) throws {
        do {
            let data = try Data(contentsOf: url)
            configuration = try PropertyListDecoder().decode(Configuration.self, from: data)
        } catch {
            log.error("\(url) is not valid")
        }
    }
    
    public func configure() {
        guard let url = Bundle.main.url(forResource: "nugu-config", withExtension: "plist") else {
            log.error("nugu-config.plist is not exist")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            configuration = try PropertyListDecoder().decode(Configuration.self, from: data)
        } catch {
            log.error("nugu-config.plist is not valid")
        }
    }
}

// MAKR: - Url

public extension ConfigurationStore {
    func isServiceWebRedirectUrl(url: URL) -> Bool {
        guard let configuration = configuration else {
            log.error("ConfigurationSotre is not configured")
            return false
        }
     
        return url.absoluteString.starts(with: configuration.serviceWebRedirectUri)
    }
    
    func isAuthorizationRedirectUrl(url: URL) -> Bool {
        guard let configuration = configuration else {
            log.error("ConfigurationSotre is not configured")
            return false
        }
     
        return url.absoluteString.starts(with: configuration.authRedirectUri)
    }

    func privacyUrl(completion: (Result<URL, Error>) -> Void) {
        // TODO: Get from OAuth discovery API
        if let url = URL(string: "https://privacy.sktelecom.com/view.do?ctg=policy&name=policy") {
            completion(.success(url))
        } else {
            completion(.failure(ConfigurationError.invalidUrl))
        }
    }
    
    /// Web page url for NUGU usage guide of own device
    func usageGuideUrl(deviceUniqueId: String, completion: (Result<URL, Error>) -> Void) {
        guard let configuration = configuration else {
            completion(.failure(ConfigurationError.notConfigured))
            return
        }
        
        // TODO: Get from OAuth discovery API
        var urlComponent = URLComponents(string: "https://webview.sktnugu.com/v2/3pp/confirm.html")
        urlComponent?.queryItems = [
            URLQueryItem(name: "poc_id", value: configuration.pocId),
            URLQueryItem(name: "device_unique_id", value: deviceUniqueId)
        ]
        if let url = urlComponent?.url {
            completion(.success(url))
        } else {
            completion(.failure(ConfigurationError.invalidUrl))
        }
    }
    
    func serviceSettingUrl(completion: (Result<URL, Error>) -> Void) {
        // TODO: Get from OAuth discovery API
        if let url = URL(string: "https://webview.sktnugu.com/3pp/main.html?screenCode=setting_webview") {
            completion(.success(url))
        } else {
            completion(.failure(ConfigurationError.invalidUrl))
        }
    }
    
    func agreementUrl(completion: (Result<URL, Error>) -> Void) {
        // TODO: Get from OAuth discovery API
        if let url = URL(string: "https://webview.sktnugu.com/3pp/agreement/list.html") {
            completion(.success(url))
        } else {
            completion(.failure(ConfigurationError.invalidUrl))
        }
    }
}
