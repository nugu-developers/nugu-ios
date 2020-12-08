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

import NuguCore
import NuguLoginKit

/// The entry point of NUGU SDKs.
///
/// Application should configure `ConfigurationStore` using `configure()`, `configure(url:)` or `configure(configuration:)`
public class ConfigurationStore {
    public static let shared = ConfigurationStore()
    
    public var configuration: Configuration? {
        didSet {
            log.debug(configuration)
            guard let configuration = configuration else { return }
            
            NuguOAuthServerInfo.serverBaseUrl = configuration.authServerUrl
            requestDiscovery(completion: nil)
        }
    }
    
    private var configurationMetadata: ConfigurationMetadata? {
        didSet {
            log.debug(configurationMetadata)
            guard let configurationMetadata = configurationMetadata else { return }
            
            if let address = configurationMetadata.deviceGatewayServerH2Uri {
                NuguServerInfo.resourceServerAddress = address
            }
            if let address = configurationMetadata.deviceGatewayRegistryUri {
                NuguServerInfo.registryServerAddress = address
            }
        }
    }
    
    // singleton
    private init() {}
    
    /// Configure with `Configuration`
    public func configure(configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Configure with specific `url`
    public func configure(url: URL) throws {
        do {
            let data = try Data(contentsOf: url)
            configuration = try PropertyListDecoder().decode(Configuration.self, from: data)
        } catch {
            log.error("\(url) is not valid")
        }
    }
    
    /// Configure with `nugu-config.plist` in `Bundle.main`
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
    /// Determine whether the `url` is `Configuration.serviceWebRedirectUri`.
    func isServiceWebRedirectUrl(url: URL) -> Bool {
        guard let configuration = configuration else {
            log.error("ConfigurationStore is not configured")
            return false
        }
        
        return url.absoluteString.starts(with: configuration.serviceWebRedirectUri)
    }
    
    /// Determine whether the `url` is `Configuration.authRedirectUri`.
    func isAuthorizationRedirectUrl(url: URL) -> Bool {
        guard let configuration = configuration else {
            log.error("ConfigurationStore is not configured")
            return false
        }
        
        return url.absoluteString.starts(with: configuration.authRedirectUri)
    }
    
    /// Get the web page url for the privacy policy.
    ///
    /// - Parameter completion: The closure to receive result.
    func privacyUrl(completion: @escaping (Result<String, Error>) -> Void) {
        configurationMetadata { result in
            switch result {
            case .success(let configurationMetadata):
                if let urlString = configurationMetadata.policyUri {
                    completion(.success(urlString))
                } else {
                    completion(.failure(ConfigurationError.invalidUrl))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get the web page url for NUGU usage guide of own device
    ///
    /// - Parameter completion: The closure to receive result.
    func usageGuideUrl(deviceUniqueId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let configuration = configuration else {
            completion(.failure(ConfigurationError.notConfigured))
            return
        }
        
        configurationMetadata { result in
            switch result {
            case .success(let configurationMetadata):
                guard let serviceDocumentation = configurationMetadata.serviceDocumentation else {
                    completion(.failure(ConfigurationError.invalidUrl))
                    return
                }
                var urlComponent = URLComponents(string: serviceDocumentation)
                urlComponent?.queryItems = [
                    URLQueryItem(name: "poc_id", value: configuration.pocId),
                    URLQueryItem(name: "device_unique_id", value: deviceUniqueId)
                ]
                if let urlString = urlComponent?.url?.absoluteString {
                    completion(.success(urlString))
                } else {
                    completion(.failure(ConfigurationError.invalidUrl))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get the web page url to configure play settings for the user device.
    ///
    /// - Parameter completion: The closure to receive result.
    func serviceSettingUrl(completion: @escaping (Result<String, Error>) -> Void) {
        configurationMetadata { result in
            switch result {
            case .success(let configurationMetadata):
                if let urlString = configurationMetadata.serviceSetting {
                    completion(.success(urlString))
                } else {
                    completion(.failure(ConfigurationError.invalidUrl))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get the web page url for the terms of service.
    ///
    /// - Parameter completion: The closure to receive result.
    func agreementUrl(completion: @escaping (Result<String, Error>) -> Void) {
        configurationMetadata { result in
            switch result {
            case .success(let configurationMetadata):
                if let urlString = configurationMetadata.termOfServiceUri {
                    completion(.success(urlString))
                } else {
                    completion(.failure(ConfigurationError.invalidUrl))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func configurationMetadata(completion: @escaping (Result<ConfigurationMetadata, Error>) -> Void) {
        guard let configurationMetadata = configurationMetadata else {
            requestDiscovery(completion: completion)
            return
        }
        
        completion(.success(configurationMetadata))
    }
}

// MARK: - Private

private extension ConfigurationStore {
    func requestDiscovery(completion: ((Result<ConfigurationMetadata, Error>) -> Void)?) {
        configurationMetadata = nil
        guard let configuration = configuration else {
            completion?(.failure(ConfigurationError.notConfigured))
            return
        }
        guard let url = URL(string: configuration.discoveryUri) else {
            completion?(.failure(ConfigurationError.invalidUrl))
            return
        }
        
        let dataTask = URLSession.shared.dataTask(
            with: URLRequest(url: url),
            completionHandler: { [weak self] (data, _, error) in
                guard error == nil else {
                    log.error(error)
                    completion?(.failure(error!))
                    return
                }
                guard let data = data,
                      let configurationMetadata = try? JSONDecoder().decode(ConfigurationMetadata.self, from: data) else {
                    log.error(error)
                    completion?(.failure(ConfigurationError.invalidPayload))
                    return
                }
                
                completion?(.success(configurationMetadata))
                self?.configurationMetadata = configurationMetadata
            })
        dataTask.resume()
    }
}
