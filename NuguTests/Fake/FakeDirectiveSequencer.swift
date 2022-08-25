//
//  FakeDirectiveSequencer.swift
//  NuguTests
//
//  Created by jaycesub on 2022/08/17.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
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

class FakeDirectiveSequencer: DirectiveSequenceable {
    
    private var directiveHandleInfos = DirectiveHandleInfos()
    var directiveResults: DirectiveHandleResult?
    
    func add(directiveHandleInfos: DirectiveHandleInfos) {
        self.directiveHandleInfos = directiveHandleInfos
    }
    
    func remove(directiveHandleInfos: DirectiveHandleInfos) {
        self.directiveHandleInfos.removeAll()
    }
    
    func processDirective(_ directive: Downstream.Directive) {
        guard let handler = directiveHandleInfos[directive.header.type] else {
            return
        }
        
        handler.directiveHandler(directive) { [weak self] result in
            self?.directiveResults = result
        }
    }
    
    func processAttachment(_ attachment: Downstream.Attachment) {
        // Nothing to do.
    }
    
    func cancelDirective(dialogRequestId: String) {
        // Nothing to do.
    }
}
