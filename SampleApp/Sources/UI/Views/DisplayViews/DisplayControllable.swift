//
//  DisplayControllable.swift
//  SampleApp
//
//  Created by jin kim on 2020/01/29.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
//

import NuguAgents

protocol DisplayControllable {
    func focusedItemToken() -> String?
    func visibleTokenList() -> [String]?
    
    func focus(direction: DisplayControlPayload.Direction) -> Bool
    func scroll(direction: DisplayControlPayload.Direction) -> Bool
}

// MARK: - Optional
// DisplayAgent in iOS SampleApp does not support focus by default.
extension DisplayControllable {
    func focusedItemToken() -> String? {
        return nil
    }
    
    func focus(direction: DisplayControlPayload.Direction) -> Bool {
        return false
    }
}
