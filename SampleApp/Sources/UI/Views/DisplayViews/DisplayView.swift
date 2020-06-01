//
//  DisplayView.swift
//  SampleApp
//
//  Created by jin kim on 2019/11/06.
//  Copyright © 2019 SK Telecom Co., Ltd. All rights reserved.
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

import UIKit

import NuguUIKit

class DisplayView: UIView {
    @IBOutlet weak var titleView: DisplayTitleView!
    
    @IBOutlet weak var subTitleContainerView: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var subIconImageView: UIImageView!
    
    @IBOutlet weak var contentButtonContainerView: UIView!
    @IBOutlet weak var contentButton: ContentButton!
    
    @IBOutlet weak var idleBar: DisplayIdleBar!
    
    var onCloseButtonClick: (() -> Void)?
    
    var onItemSelect: ((_ token: String?) -> Void)?
    
    var onUserInteraction: (() -> Void)?
    
    var onNuguButtonClick: (() -> Void)? {
        didSet {
            idleBar.onNuguButtonClick = onNuguButtonClick
        }
    }
    
    var onChipsSelect: ((_ text: String?) -> Void)? {
        didSet {
            idleBar.onChipsSelect = onChipsSelect
        }
    }
    
    var displayPayload: Data?
    
    var contentButtonToken: String?
    
    var supportFocusedItemToken: Bool? {
        guard let displayPayload = displayPayload,
            let payloadDictionary = try? JSONSerialization.jsonObject(with: displayPayload, options: []) as? [String: AnyHashable],
            let isSupportFocusedItemToken = payloadDictionary["supportFocusedItemToken"] as? Bool else {
                return nil
        }
        return isSupportFocusedItemToken
    }
    
    var supportVisibleTokenList: Bool? {
        guard let displayPayload = displayPayload,
            let payloadDictionary = try? JSONSerialization.jsonObject(with: displayPayload, options: []) as? [String: AnyHashable],
            let isSupportVisibleTokenList = payloadDictionary["supportVisibleTokenList"] as? Bool else {
                return nil
        }
        return isSupportVisibleTokenList
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromXib()
    }
    
    func loadFromXib() {}
    
    func update(updatePayload: Data) {
        guard let displayingPayloadData = displayPayload,
            let displayingPayloadDictionary = try? JSONSerialization.jsonObject(with: displayingPayloadData, options: []) as? [String: AnyHashable],
            let updatePayloadDictionary = try? JSONSerialization.jsonObject(with: updatePayload, options: []) as? [String: AnyHashable] else {
                return
        }
        let mergedPayloadDictionary = displayingPayloadDictionary.merged(with: updatePayloadDictionary)
        guard let mergedPayloadData = try? JSONSerialization.data(withJSONObject: mergedPayloadDictionary, options: []) else { return }
        displayPayload = mergedPayloadData
    }
    
    @IBAction func contentButtonDidClick(_ button: UIButton) {
        onItemSelect?(contentButtonToken)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        onUserInteraction?()
        return super.hitTest(point, with: event)
    }
}
