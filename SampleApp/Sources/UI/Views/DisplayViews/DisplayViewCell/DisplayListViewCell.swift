//
//  DisplayListViewCell.swift
//  SampleApp
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

final class DisplayListViewCell: UITableViewCell {
    
    @IBOutlet private weak var numberLabel: UILabel!
    @IBOutlet private weak var displayImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    
    @IBOutlet private weak var imageToggle: UIButton!
    @IBOutlet private weak var textToggle: UIButton!
    
    private var token: String?
    
    var onToggleSelect: ((_ token: String) -> Void)?
    
    func configure(index: String?, item: DisplayListTemplate.Item?) {
        numberLabel.text = index
        
        if let imageUrl = item?.image?.sources.first?.url {
            displayImageView.loadImage(from: imageUrl)
            displayImageView.isHidden = false
        } else {
            displayImageView.isHidden = true
        }
        
        titleLabel.text = item?.header?.text
        titleLabel.textColor = UIColor.textColor(rgbHexString: item?.header?.color)
        subTitleLabel.text = item?.footer?.text
        subTitleLabel.textColor = UIColor.textColor(rgbHexString: item?.footer?.color)
        
        guard let toggle = item?.toggle else {
            imageToggle.isHidden = true
            textToggle.isHidden = true
            token = nil
            return
        }
        
        switch toggle.style {
        case .image:
            imageToggle.isHidden = false
            textToggle.isHidden = true
            imageToggle.isSelected = (toggle.status == .on)
        case .text:
            imageToggle.isHidden = true
            textToggle.isHidden = false
            textToggle.isSelected = (toggle.status == .on)
            textToggle.layer.cornerRadius = textToggle.bounds.size.height/2.0
            textToggle.backgroundColor = (toggle.status == .on) ? UIColor(rgbHexString: "009dff") : UIColor(rgbHexString: "acacac")
        }
        token = toggle.token
    }
}

private extension DisplayListViewCell {
    @IBAction func toggleButtonDidClick(toggleButton: UIButton) {
        guard let token = token else { return }
        onToggleSelect?(token)
    }
}
