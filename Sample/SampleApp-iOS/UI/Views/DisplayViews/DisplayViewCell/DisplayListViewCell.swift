//
//  DisplayListViewCell.swift
//  SampleApp-iOS
//
//  Created by jin kim on 16/08/2019.
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

final class DisplayListViewCell: UITableViewCell {
    
    @IBOutlet private weak var numberLabel: UILabel!
    @IBOutlet private weak var displayImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    
    func configure(index: String?, item: DisplayTemplate.ListTemplate.Item?) {
        numberLabel.text = index
        
        if let imageUrl = item?.image?.sources.first?.url { // first 사용?
            displayImageView.loadImage(from: imageUrl)
            displayImageView.isHidden = false
        } else {
            displayImageView.isHidden = true
        }
        
        titleLabel.text = item?.header.text
        titleLabel.textColor = UIColor(rgbHexString: item?.header.color)
        subTitleLabel.text = item?.footer?.text
        subTitleLabel.textColor = UIColor(rgbHexString: item?.footer?.color)
    }
}
