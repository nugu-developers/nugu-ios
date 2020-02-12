//
//  DisplayBodyListViewCell.swift
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

final class DisplayBodyListViewCell: UITableViewCell {
    
    @IBOutlet private weak var numberLabel: UILabel!
    @IBOutlet private weak var displayImageView: UIImageView!
    @IBOutlet private weak var displayIamgeViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private var bodyLabels: [UILabel]!
    @IBOutlet private weak var footerLabel: UILabel!
    
    func configure(index: String?, item: DisplayBodyListTemplate.Item?) {
        numberLabel.text = index
        
        if let imageUrl = item?.image?.sources.first?.url {
            displayImageView.loadImage(from: imageUrl)
            displayIamgeViewWidthConstraint.constant = 84.0
        } else {
            displayIamgeViewWidthConstraint.constant = 0
        }
        
        titleLabel.text = item?.header.text
        titleLabel.textColor = UIColor.textColor(rgbHexString: item?.header.color)
        
        item?.body?.enumerated().forEach({ (index, commonText) in
            bodyLabels[index].isHidden = false
            bodyLabels[index].text = commonText.text
            bodyLabels[index].textColor = UIColor.textColor(rgbHexString: commonText.color)
        })
        
        footerLabel.text = item?.footer?.text
        footerLabel.textColor = UIColor.textColor(rgbHexString: item?.footer?.color)
    }
}
