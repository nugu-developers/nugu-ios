//
//  TextList2ViewCell.swift
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

final class TextList2ViewCell: UITableViewCell {
    @IBOutlet private weak var whiteBackgroundView: UIView!
    
    @IBOutlet private weak var numberLabelContainerView: UIView!
    @IBOutlet private weak var numberLabel: UILabel!
    
    @IBOutlet private weak var headerLabelContainerView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    
    @IBOutlet private weak var contentImageViewContainerView: UIView!
    @IBOutlet private weak var contentImageView: UIImageView!
    
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    
    @IBOutlet private weak var toggleContainerView: UIView!
    @IBOutlet private weak var toggleButton: UIButton!
    
    private var token: String?
    var onToggleSelect: ((_ token: String) -> Void)?
    
    func configure(badgeNumber: String?, item: TextList2Template.Item?, toggleStyle: DisplayCommonTemplate.Common.ToggleStyle?) {
        whiteBackgroundView.clipsToBounds = true
        whiteBackgroundView.layer.cornerRadius = 8.0
        whiteBackgroundView.layer.borderColor = UIColor(red: 236.0/255.0, green: 236.0/255.0, blue: 236.0/255.0, alpha: 1.0).cgColor
        whiteBackgroundView.layer.borderWidth = 1.0
        
        numberLabel.text = badgeNumber
        numberLabelContainerView.isHidden = (badgeNumber == nil)
        
        headerLabel.setDisplayText(displayText: item?.header)
        headerLabelContainerView.isHidden = (item?.header == nil)
        
        // Set content image
        contentImageView.clipsToBounds = true
        contentImageView.layer.cornerRadius = 2.0
        if let contentUrl = item?.image.sources.first?.url {
            contentImageView.loadImage(from: contentUrl)
            contentImageViewContainerView.isHidden = false
        } else {
            contentImageViewContainerView.isHidden = true
        }
        
        bodyLabel.setDisplayText(displayText: item?.body)
        footerLabel.setDisplayText(displayText: item?.footer)
        
        if let toggle = item?.toggle {
            toggleContainerView.isHidden = false
            switch toggle.style {
            case .image:
                if toggle.status == .on {
                    toggleButton.loadImage(from: toggleStyle?.image?.on?.sources.first?.url)
                } else {
                    toggleButton.loadImage(from: toggleStyle?.image?.off?.sources.first?.url)
                }
                toggleButton.setTitle(nil, for: .normal)
            case .text:
                toggleButton.setImage(nil, for: .normal)
                if toggle.status == .on {
                    toggleButton.setTitle(toggleStyle?.text?.on?.text, for: .normal)
                } else {
                    toggleButton.setTitle(toggleStyle?.text?.off?.text, for: .normal)
                }
            }
        } else {
            toggleContainerView.isHidden = true
        }
        
        token = item?.toggle?.token
    }
}

private extension TextList2ViewCell {
    @IBAction func toggleButtonDidClick(toggleButton: UIButton) {
        guard let token = token else { return }
        onToggleSelect?(token)
    }
}
