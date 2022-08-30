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
import NuguUtils
import NuguLoginKit
import NuguUIKit

/// The entry point of NUGU SDKs.
///
/// Application should configure `ConfigurationStore` using `configure()`, `configure(url:)` or `configure(configuration:)`
public class ConfigurationStore {
    public static let shared = ConfigurationStore()
    private let discoveryQueue = DispatchQueue(label: "com.sktelecom.romaine.jademarble.tyche_end_point_detector")
    private let urlSession = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: nil)
    
    public var configuration: Configuration? {
        didSet {
            log.debug("configuration set: \(configuration.debugDescription)")
            guard let configuration = configuration else { return }
            
            NuguOAuthServerInfo.serverBaseUrl = configuration.authServerUrl
            NuguDisplayWebView.deviceTypeCode = configuration.deviceTypeCode
            
            requestDiscovery(completion: nil)
        }
    }
    
    @Atomic public var configurationMetadata: ConfigurationMetadata?
    
    /// Configure with `Configuration`
    public func configure(configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Configure with specific `url`
    public func configure(url: URL) {
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
    
    /// Get the registry server url for server initiated directive
    ///
    /// - Parameter completion: The closure to receive result.
    func registryServerUrl(completion: @escaping (Result<String, Error>) -> Void) {
        configurationMetadata { result in
            guard case let .success(metadata) = result,
                  let registryServerUrl = metadata.deviceGatewayRegistryUri ?? NuguServerInfo.registryServerAddress else {
                completion(.failure(ConfigurationError.invalidUrl))
                return
            }
            
            completion(.success(registryServerUrl))
        }
    }
    
    /// Get the normal device gateway url for the events and the directives
    ///
    /// - Parameter completion: The closure to receive result.
    func l4SwitchUrl(completion: @escaping (Result<String, Error>) -> Void) {
        configurationMetadata { result in
            guard case let .success(metadata) = result,
                  let l4SwitchUrl = metadata.deviceGatewayServerH2Uri else {
                completion(.failure(ConfigurationError.invalidUrl))
                return
            }
            
            completion(.success(l4SwitchUrl))
        }
    }
}

// MARK: - Private

private extension ConfigurationStore {
    func configurationMetadata(completion: @escaping (Result<ConfigurationMetadata, Error>) -> Void) {
        discoveryQueue.async { [weak self] in
            guard let configurationMetadata = self?.configurationMetadata else {
                self?.requestDiscovery(completion: completion)
                return
            }
            
            completion(.success(configurationMetadata))
        }
    }
    
    func requestDiscovery(completion: ((Result<ConfigurationMetadata, Error>) -> Void)?) {
        guard let configuration = configuration else {
            completion?(.failure(ConfigurationError.notConfigured))
            return
        }
        
        guard let url = URL(string: configuration.discoveryUri) else {
            completion?(.failure(ConfigurationError.invalidUrl))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        guard let base64AuthInfo = "\(configuration.authClientId):\(configuration.authClientSecret)"
                .data(using: .utf8)?
                .base64EncodedString() else {
            completion?(.failure(ConfigurationError.notConfigured))
            return
        }
        
        urlRequest.addValue(
            "Basic \(base64AuthInfo)",
            forHTTPHeaderField: "Authorization"
        )
        
        urlSession.dataTask(with: urlRequest) { [weak self] (data, _, error) in
            self?.discoveryQueue.async { [weak self] in
                guard error == nil else {
                    log.error(error)
                    completion?(.failure(error!))
                    return
                }
                guard let data = data,
                      let metaData = try? JSONDecoder().decode(ConfigurationMetadata.self, from: data) else {
                          log.error(error)
                          self?.configurationMetadata = nil
                          completion?(.failure(ConfigurationError.invalidPayload))
                          return
                      }
                
                if let url = metaData.templateServerUri {
                    NuguDisplayWebView.displayWebServerAddress = url
                }
                
                self?.configurationMetadata = metaData
                log.debug("configuration metadata: \(metaData)")
                
                completion?(.success(metaData))
            }
        }.resume()
    }
}
