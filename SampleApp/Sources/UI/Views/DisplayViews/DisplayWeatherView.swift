//
//  DisplayWeatherView.swift
//  SampleApp
//
//  Created by jin kim on 2019/12/13.
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

final class DisplayWeatherView: DisplayView {
    
    @IBOutlet private weak var locationButton: UIButton!
    
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var contentImageView: UIImageView!
    
    @IBOutlet private weak var currentTemperatureLabel: UILabel!
    @IBOutlet private weak var minTemperatureLabel: UILabel!
    @IBOutlet private weak var maxTemperatureLabel: UILabel!
    
    @IBOutlet private weak var bodyLabel: UILabel!
    
    @IBOutlet private var weathersLabels: [UILabel]!
    @IBOutlet private var weathersImageViews: [UIImageView]!
    
    override var displayPayload: String? {
        didSet {
            guard let payloadData = displayPayload?.data(using: .utf8),
            let displayItem = try? JSONDecoder().decode(DisplayWeatherTemplate.self, from: payloadData) else { return }
            
            titleLabel.text = displayItem.title.text.text
            titleLabel.textColor = UIColor.textColor(rgbHexString: displayItem.title.text.color)

            locationButton.setTitle(displayItem.title.subtext?.text, for: .normal)
            
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
            
            if let logoUrl = displayItem.title.logo.sources.first?.url {
                logoImageView.loadImage(from: logoUrl)
                logoImageView.isHidden = false
            } else {
                logoImageView.isHidden = true
            }

            headerLabel.text = displayItem.content.header?.text ?? "-"
            headerLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.header?.color)
            
            if let contentUrl = displayItem.content.image?.sources.first?.url {
                contentImageView.loadImage(from: contentUrl)
            } else {
                contentImageView.image = nil
            }
            
            if let currentTemperature = displayItem.content.temperature?.current {
                currentTemperatureLabel.text = currentTemperature.text
                currentTemperatureLabel.textColor = UIColor.textColor(rgbHexString: currentTemperature.color)
                currentTemperatureLabel.isHidden = false
            } else {
                currentTemperatureLabel.isHidden = true
            }
            
            minTemperatureLabel.text = displayItem.content.temperature?.min?.text
            minTemperatureLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.temperature?.min?.color)
            
            maxTemperatureLabel.text = displayItem.content.temperature?.max?.text
            maxTemperatureLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.temperature?.max?.color)
            
            if let bodyTextData = displayItem.content.body.text.data(using: .utf8),
                let attributedBodyText = try? NSAttributedString(
                    data: bodyTextData,
                    options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                    documentAttributes: nil
                ) {
                bodyLabel.attributedText = attributedBodyText
                bodyLabel.textAlignment = .center
            } else {
                bodyLabel.text = displayItem.content.body.text
                bodyLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.body.color)
            }
            
            displayItem.content.listItems?.enumerated().forEach({ (index, item) in
                weathersLabels[index].text = item.header?.text
                weathersLabels[index].textColor = UIColor.textColor(rgbHexString: item.header?.color)
                
                if let weatherIconUrl = item.image?.sources.first?.url {
                    weathersImageViews[index].loadImage(from: weatherIconUrl)
                } else {
                    weathersImageViews[index].image = nil
                }
            })
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("DisplayWeatherView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        addBorderToTitleContainerView()
        contentImageView.layer.cornerRadius = 4.0
        contentImageView.clipsToBounds = true
    }
}
