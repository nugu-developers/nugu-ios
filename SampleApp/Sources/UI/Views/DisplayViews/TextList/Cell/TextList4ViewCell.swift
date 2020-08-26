//
//  TextList4ViewCell.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/18.
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

import UIKit

final class TextList4ViewCell: UITableViewCell {
    @IBOutlet private weak var whiteBackgroundView: UIView!
    
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private var bodyLabels: [UILabel]!
    
    @IBOutlet private weak var buttonContainerView: UIView!
    @IBOutlet private weak var button: UIButton!
    
    private var buttonEventType: DisplayItemEventType?
    var onButtonSelect: ((_ eventType: DisplayItemEventType) -> Void)?
    
    func configure(item: TextList4Template.Item?) {
        whiteBackgroundView.clipsToBounds = true
        whiteBackgroundView.layer.cornerRadius = 8.0
        whiteBackgroundView.layer.borderColor = UIColor(red: 236.0/255.0, green: 236.0/255.0, blue: 236.0/255.0, alpha: 1.0).cgColor
        whiteBackgroundView.layer.borderWidth = 1.0
        
        headerLabel.setDisplayText(displayText: item?.header)
        
        bodyLabels.forEach { bodyLabel in
            bodyLabel.setDisplayText(displayText: nil)
        }
        if let body = item?.body {
            body.enumerated().forEach({ [weak self] (index, body) in
                guard let self = self,
                    index < self.bodyLabels.count else { return }
                self.bodyLabels[index].setDisplayText(displayText: body)
            })
        }
        
        button.layer.cornerRadius = button.frame.size.height/2
        button.layer.borderColor = UIColor(red: 0, green: 157.0/255.0, blue: 1, alpha: 1.0).cgColor
        button.layer.borderWidth = 1.0
        button.setTitleColor(UIColor(red: 0, green: 157.0/255.0, blue: 1, alpha: 1.0), for: .normal)
        if let itemButton = item?.button {
            buttonContainerView.isHidden = false
            button.setTitle(itemButton.text, for: .normal)
        } else {
            buttonContainerView.isHidden = true
        }
        switch item?.button?.eventType {
        case .elementSelected:
            buttonEventType = .elementSelected(token: item?.button?.token, postback: item?.button?.postback)
        case .textInput:
            buttonEventType = .textInput(textInput: item?.button?.textInput)
        default:
            buttonEventType = nil
        }
    }
}

private extension TextList4ViewCell {
    @IBAction func buttonDidClick(_ button: UIButton) {
        guard let buttonEventType = buttonEventType else { return }
        onButtonSelect?(buttonEventType)
    }
}
