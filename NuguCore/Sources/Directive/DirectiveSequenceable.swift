//
//  DirectiveSequenceable.swift
//  NuguCore
//
//  Created by childc on 15/02/2020.
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

/// <#Description#>
public protocol DirectiveSequenceable {
    /// Adds a listener to be notified of `Directive` handling states.
    /// - Parameter listener: The object to add.
    func addListener(_ listener: DirectiveSequencerListener)
    
    /// Removes a listener from directive-sequencer.
    /// - Parameter listener: The object to remove.
    func removeListener(_ listener: DirectiveSequencerListener)
    
    /**
     Add directive handler.
     
     You can add attachment handler also.
     */
    func add(directiveHandleInfos: DirectiveHandleInfos)
    
    /**
     Remove directive handler.
     
     You can remove attachment handler also.
     */
    func remove(directiveHandleInfos: DirectiveHandleInfos)
    
    /**
     Dispatch directive to pre-registered handler
     */
    func processDirective(_ directive: Downstream.Directive)
    
    /**
     Dispatch attachment to pre-registered handler
     */
    func processAttachment(_ attachment: Downstream.Attachment)
}
