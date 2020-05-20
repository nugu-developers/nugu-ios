//
//  Weather4ViewCell.swift
//  SampleApp
//
//  Created by jin kim on 2019/12/16.
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

final class Weather4ViewCell: UITableViewCell {
    
    @IBOutlet private weak var whiteBackgroundView: UIView!
    
    @IBOutlet private weak var weatherTitleLabel: UILabel!
    @IBOutlet private weak var weatherSubTitleLabel: UILabel!
    @IBOutlet private weak var weatherImageView: UIImageView!
    
    @IBOutlet private weak var minTemperatureLabel: UILabel!
    @IBOutlet private weak var maxTemperatureLabel: UILabel!
    
    func configure(item: Weather4Template.Content.Item?) {
        whiteBackgroundView.clipsToBounds = true
        whiteBackgroundView.layer.cornerRadius = 8.0
        whiteBackgroundView.layer.borderColor = UIColor(red: 236.0/255.0, green: 236.0/255.0, blue: 236.0/255.0, alpha: 1.0).cgColor
        whiteBackgroundView.layer.borderWidth = 1.0
        
        weatherTitleLabel.text = item?.header?.text ?? "-"
        weatherTitleLabel.textColor = UIColor.textColor(rgbHexString: item?.header?.color)
        
        weatherSubTitleLabel.text = item?.body?.text
        weatherSubTitleLabel.textColor = UIColor.textColor(rgbHexString: item?.body?.color)
        
        if let imageUrl = item?.image?.sources.first?.url {
            weatherImageView.loadImage(from: imageUrl)
            weatherImageView.isHidden = false
        } else {
            weatherImageView.isHidden = true
        }
        
        minTemperatureLabel.text = item?.temperature?.min?.text ?? "-"
        minTemperatureLabel.textColor = UIColor.textColor(rgbHexString: item?.temperature?.min?.color)
        
        maxTemperatureLabel.text = item?.temperature?.max?.text ?? "-"
        maxTemperatureLabel.textColor = UIColor.textColor(rgbHexString: item?.temperature?.max?.color)
    }
}
