//
//  Weather3View.swift
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

final class Weather3View: DisplayView {
    
    @IBOutlet private var headerLabels: [UILabel]!
    @IBOutlet private var contentImageViews: [UIImageView]!
    @IBOutlet private var bodyLabels: [UILabel]!
    @IBOutlet private var minTemperatureLabels: [UILabel]!
    @IBOutlet private var maxTemperatureLabels: [UILabel]!
    @IBOutlet private var footerLabels: [UILabel]!
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(Weather3Template.self, from: payloadData) else { return }
            
            // Set backgroundColor
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
                        
            // Set title
            titleView.setData(titleData: displayItem.title)
            
            // Set sub title
            if let subIconUrl = displayItem.title.subicon?.sources.first?.url {
                subIconImageView.loadImage(from: subIconUrl)
                subIconImageView.isHidden = false
            } else {
                subIconImageView.isHidden = true
            }
            subTitleLabel.setDisplayText(displayText: displayItem.title.subtext)
            subTitleContainerView.isHidden = (displayItem.title.subtext == nil)
            
            // Set content button
            if let buttonItem = displayItem.title.button {
                contentButtonContainerView.isHidden = false
                contentButton.setTitle(buttonItem.text, for: .normal)
                contentButtonToken = buttonItem.token
            } else {
                contentButtonContainerView.isHidden = true
            }
            
            displayItem.content.listItems?.enumerated().forEach { [weak self] (index, item) in
                guard let self = self,
                    let listItems = displayItem.content.listItems,
                    index < listItems.count else { return }
                self.headerLabels[index].setDisplayText(displayText: item.header)
                self.bodyLabels[index].setDisplayText(displayText: item.body)
                if let contentUrl = item.image?.sources.first?.url {
                    contentImageViews[index].loadImage(from: contentUrl)
                } else {
                    contentImageViews[index].image = nil
                }
                self.minTemperatureLabels[index].setDisplayText(displayText: item.temperature?.min)
                self.maxTemperatureLabels[index].setDisplayText(displayText: item.temperature?.max)
                self.footerLabels[index].setDisplayText(displayText: item.header)
            }
                    
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("Weather3View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
    }
}
