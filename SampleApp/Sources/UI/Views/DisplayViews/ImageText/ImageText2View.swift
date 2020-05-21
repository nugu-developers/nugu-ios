//
//  ImageText2View.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/13.
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

import NuguUIKit

final class ImageText2View: DisplayView {
    
    @IBOutlet private weak var contentImageViewContainerView: UIView!
    @IBOutlet private weak var contentImageView: UIImageView!
    
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(ImageText1Template.self, from: payloadData) else { return }
            
            // Set backgroundColor
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
                        
            // Set title
            titleView.setData(titleData: displayItem.title)
            titleView.onCloseButtonClick = { [weak self] in
                self?.onCloseButtonClick?()
            }
            
            // Set sub title
            if let subIconUrl = displayItem.title.subicon?.sources.first?.url {
                subIconImageView.loadImage(from: subIconUrl)
                subIconImageView.isHidden = false
            } else {
                subIconImageView.isHidden = true
            }
            subTitleLabel.setDisplayText(displayText: displayItem.title.subtext)
            subTitleContainerView.isHidden = (displayItem.title.subtext == nil)
            
            // Set content image
            if let contentUrl = displayItem.content.image.sources.first?.url {
                contentImageView.loadImage(from: contentUrl)
                contentImageViewContainerView.isHidden = false
            } else {
                contentImageViewContainerView.isHidden = true
            }
            
            // Set content labels
            headerLabel.setDisplayText(displayText: displayItem.content.header)
            bodyLabel.setDisplayText(displayText: displayItem.content.body)
            footerLabel.setDisplayText(displayText: displayItem.content.footer)
            
            // Set content button
            if let buttonItem = displayItem.title.button {
                contentButtonContainerView.isHidden = false
                contentButton.setTitle(buttonItem.text, for: .normal)
                contentButtonToken = buttonItem.token
            } else {
                contentButtonContainerView.isHidden = true
            }
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("ImageText2View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        contentImageView.clipsToBounds = true
        contentImageView.layer.cornerRadius = 8.0
    }
}
