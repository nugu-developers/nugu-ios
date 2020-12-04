//
//  ConfigurationMetadata.swift
//  NuguClientKit
//
//  Created by 이민철님/AI Assistant개발Cell on 2020/11/30.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

public struct ConfigurationMetadata: Decodable {
    let issuer: String?
    let authorizationEndpoint: String?
    let tokenEndpoint: String?
    let tokenEndpointAuthMethodsSupported: [String]?
    let responseTypesSupported: [String]?
    let grantTypesSupported: [String]?
    let introspectionEndpoint: String?
    let introspectionEndpointAuthMethodsSupported: [String]?
    let revocationEndpoint: String?
    let revocationEndpointAuthMethodsSupported: [String]?
    let deviceGatewayRegistryUri: String?
    let deviceGatewayServerGrpcUri: String?
    let deviceGatewayServerH2Uri: String?
    let templateServerUri: String?
    let policyUri: String?
    let termOfServiceUri: String?
    let serviceDocumentation: String?
    let serviceSetting: String?
    
    enum CodingKeys: String, CodingKey {
        case issuer = "issuer"
        case authorizationEndpoint = "authorization_endpoint"
        case tokenEndpoint = "token_endpoint"
        case tokenEndpointAuthMethodsSupported = "token_endpoint_auth_methods_supported"
        case responseTypesSupported = "response_types_supported"
        case grantTypesSupported = "grant_types_supported"
        case introspectionEndpoint = "introspection_endpoint"
        case introspectionEndpointAuthMethodsSupported = "introspection_endpoint_auth_methods_supported"
        case revocationEndpoint = "revocation_endpoint"
        case revocationEndpointAuthMethodsSupported = "revocation_endpoint_auth_methods_supported"
        case deviceGatewayRegistryUri = "device_gateway_registry_uri"
        case deviceGatewayServerGrpcUri = "device_gateway_server_grpc_uri"
        case deviceGatewayServerH2Uri = "device_gateway_server_h2_uri"
        case templateServerUri = "template_server_uri"
        case policyUri = "op_policy_uri"
        case termOfServiceUri = "op_tos_uri"
        case serviceDocumentation = "service_documentation"
        case serviceSetting = "service_setting"
    }
}
