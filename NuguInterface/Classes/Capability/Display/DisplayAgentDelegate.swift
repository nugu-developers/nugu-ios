//
//  DisplayAgentDelegate.swift
//  NuguInterface
//
//  Created by MinChul Lee on 16/05/2019.
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

/// The DisplayAgent delegate is used to notify observers when a template directive is received.
public protocol DisplayAgentDelegate: class {
    /// Determines whether the template should be displayed to user.
    /// - Parameter template: The template to display.
    /// - Returns: Application 의 시나리오에 따라 디스플레이를 원하지 않는 경우 false 를 반환해야 합니다.
    func displayAgentShouldRender(template: DisplayTemplate) -> Bool
    
    /// Tells the delegate that the specified template should be displayed.
    /// - Parameter template: The template to display.
    func displayAgentDidRender(template: DisplayTemplate)
    
    /// Determines whether the template should be remove from the screen.
    ///
    /// DialogState 가 expectingSpeech 이거나 template 요소에 대해 사용자 touch 가 발생하는 등
    /// template 이 지속적으로 노출되어야 한다고 판단될 경우, completion block 이 false 를 반환하도록 해야합니다.
    /// - Parameter template: The template to remove from the screen.
    /// - Returns: Application 의 시나리오에 따라 template 을 지속적으로 노출해야 하는 경우 false 를 반환해야 합니다.
    func displayAgentShouldClear(template: DisplayTemplate) -> Bool
    
    /// Tells the delegate that the specified template should be removed from the screen.
    /// - Parameter template: The template to remove from the screen.
    func displayAgentDidClear(template: DisplayTemplate)
}
