//
//  ImageList3ViewCell.swift
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

final class ImageList3ViewCell: UITableViewCell {
    @IBOutlet private weak var whiteBackgroundView: UIView!
    
    @IBOutlet private weak var contentImageViewContainerView: UIView!
    @IBOutlet private weak var contentImageView: UIImageView!
    
    @IBOutlet private weak var headerLabel: UILabel!
    
    @IBOutlet private weak var iconImageViewContainerView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    
    func configure(item: ImageList3Template.Item?) {
        whiteBackgroundView.clipsToBounds = true
        whiteBackgroundView.layer.cornerRadius = 8.0
        whiteBackgroundView.layer.borderColor = UIColor(red: 236.0/255.0, green: 236.0/255.0, blue: 236.0/255.0, alpha: 1.0).cgColor
        whiteBackgroundView.layer.borderWidth = 1.0
        
        // Set content image
        contentImageView.clipsToBounds = true
        contentImageView.layer.cornerRadius = 4.0
        if let contentUrl = item?.image.sources.first?.url {
            contentImageView.loadImage(from: contentUrl)
            contentImageViewContainerView.isHidden = false
        } else {
            contentImageViewContainerView.isHidden = true
        }
        
        headerLabel.setDisplayText(displayText: item?.header)
        
        if let iconUrl = item?.icon?.sources.first?.url {
            iconImageView.loadImage(from: iconUrl)
            iconImageViewContainerView.isHidden = false
        } else {
            iconImageViewContainerView.isHidden = true
        }
    }
}
