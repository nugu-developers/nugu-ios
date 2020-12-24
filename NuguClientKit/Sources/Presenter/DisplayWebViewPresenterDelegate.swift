//
//  DisplayWebViewPresenterDelegate.swift
//  NuguClientKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/12/21.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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
import NuguAgents

/// A delegate that application can extend to observe `DisplayWebViewPresenter` changes.
public protocol DisplayWebViewPresenterDelegate: class {
    /// Delegate method called when item has been selected.
    func onDisplayWebViewItemSelect(templateId: String, token: String, postback: [String: AnyHashable]?)
    /// Delegate method called when chips has been selected.
    func onDisplayWebViewChipsSelect(selectedChips: String)
    /// Delegate method called when nugu button has been selected.
    func onDisplayWebViewNuguButtonClick()
    /// Delegate method called when user interaction (scroll, touch, etc)  has been occurred.
    func onDisplayWebViewUserInteraction()
    /// Delegate method called when tap has been occurred during voice chrome is being shown.
    func onDisplayWebViewTapForStopRecognition()
    /// Delegate method called when close event has been occurred.
    func onDisplayWebViewClose()
}

// MARK: - Optional

public extension DisplayWebViewPresenterDelegate {
    func onDisplayWebViewItemSelect(templateId: String, token: String, postback: [String: AnyHashable]?) {}
    func onDisplayWebViewChipsSelect(selectedChips: String) {}
    func onDisplayWebViewUserInteraction() {}
    func onDisplayWebViewTapForStopRecognition() {}
    func onDisplayWebViewClose() {}
}
