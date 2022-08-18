//
//  FakeDirectiveSequencer.swift
//  NuguTests
//
//  Created by 신정섭님/A.출시 on 2022/08/17.
//  Copyright © 2022 SK Telecom Co., Ltd. All rights reserved.
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
