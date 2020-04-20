//
//  DisplayBodyView.swift
//  SampleApp
//
//  Created by jin kim on 14/08/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
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

final class DisplayBodyView: DisplayView {
    
    @IBOutlet private weak var contentImageViewContainerView: UIView!
    @IBOutlet private weak var contentImageView: UIImageView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(DisplayBodyTemplate.self, from: payloadData) else { return }
            
            titleLabel.text = displayItem.title.text.text
            titleLabel.textColor = UIColor.textColor(rgbHexString: displayItem.title.text.color)

            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
            
            if let logoUrl = displayItem.title.logo?.sources.first?.url {
                logoImageView.loadImage(from: logoUrl)
                logoImageView.isHidden = false
                contentImageViewContainerView.isHidden = false
            } else {
                logoImageView.isHidden = true
                contentImageViewContainerView.isHidden = true
            }

            if let contentUrl = displayItem.content.image?.sources.first?.url {
                contentImageView.loadImage(from: contentUrl)
                contentImageViewContainerView.isHidden = false
            } else {
                contentImageViewContainerView.isHidden = true
            }
            
            headerLabel.text = displayItem.content.header?.text
            headerLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.header?.color)
            
            bodyLabel.text = displayItem.content.body?.text
            bodyLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.body?.color)
            
            footerLabel.text = displayItem.content.footer?.text
            footerLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.footer?.color)
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("DisplayBodyView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        addBorderToTitleContainerView()
        contentImageView.layer.cornerRadius = 4.0
        contentImageView.clipsToBounds = true
    }
}
