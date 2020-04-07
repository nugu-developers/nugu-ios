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

class DisplayView: UIView {
    @IBOutlet weak var titleContainerView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var onCloseButtonClick: (() -> Void)?
    
    var onItemSelect: ((_ token: String?) -> Void)?
    
    var onUserInteraction: (() -> Void)?
    
    var displayPayload: Data?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromXib()
    }
    
    func loadFromXib() {}
    
    func addBorderToTitleContainerView() {
        titleContainerView.layer.cornerRadius = titleContainerView.bounds.size.height / 2.0
        titleContainerView.layer.borderColor = UIColor(rgbHexValue: 0xc9cacc).cgColor
        titleContainerView.layer.borderWidth = 1.0
    }
    
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
    
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        onUserInteraction?()
        return super.hitTest(point, with: event)
    }
}
