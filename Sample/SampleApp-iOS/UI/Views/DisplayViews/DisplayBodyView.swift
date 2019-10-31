//
//  DisplayBodyView.swift
//  SampleApp-iOS
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

import NuguInterface

final class DisplayBodyView: UIView {

    @IBOutlet private weak var titleContainerView: UIView!
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var contentImageViewContainerView: UIView!
    @IBOutlet private weak var contentImageView: UIImageView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    
    var onCloseButtonClick: (() -> Void)?
    
    var displayTemplate: DisplayTemplate.BodyTemplate? {
        didSet {
            guard let displayTemplate = displayTemplate else { return }
            
            titleLabel.text = displayTemplate.title.text.text
            titleLabel.textColor = UIColor(rgbHexString: displayTemplate.title.text.color)

            if let logoUrl = displayTemplate.title.logo.sources.first?.url {
                logoImageView.loadImage(from: logoUrl)
                contentImageViewContainerView.isHidden = false
            } else {
                contentImageViewContainerView.isHidden = true
            }
            
            if let contentUrl = displayTemplate.content.image?.sources.first?.url {
                contentImageView.loadImage(from: contentUrl)
                contentImageViewContainerView.isHidden = false
            } else {
                contentImageViewContainerView.isHidden = true
            }
            
            backgroundColor = UIColor(rgbHexString: displayTemplate.background?.color)
            
            headerLabel.text = displayTemplate.content.header?.text
            headerLabel.textColor = UIColor(rgbHexString: displayTemplate.content.header?.color)
            
            bodyLabel.text = displayTemplate.content.body?.text
            bodyLabel.textColor = UIColor(rgbHexString: displayTemplate.content.body?.color)
            
            footerLabel.text = displayTemplate.content.footer?.text
            footerLabel.textColor = UIColor(rgbHexString: displayTemplate.content.footer?.color)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadFromXib()
    }
    
    private func loadFromXib() {
        let view = Bundle.main.loadNibNamed("DisplayBodyView", owner: self)?.first as! UIView
        view.frame = bounds
        addSubview(view)
        addBorderToTitleContainerView()
        contentImageView.layer.cornerRadius = 4.0
        contentImageView.clipsToBounds = true
    }
    
    private func addBorderToTitleContainerView() {
        titleContainerView.layer.cornerRadius = titleContainerView.bounds.size.height / 2.0
        titleContainerView.layer.borderColor = UIColor(rgbHexValue: 0xc9cacc).cgColor
        titleContainerView.layer.borderWidth = 1.0
    }
    
    @IBAction private func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
}
