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
    
    @IBOutlet private weak var weatherLabel: UILabel!
    @IBOutlet private weak var weatherImageView: UIImageView!
    
    @IBOutlet private weak var temperatureStackView: UIStackView!
    @IBOutlet private weak var currentTemperatureLabel: UILabel!
    @IBOutlet private weak var minTemperatureLabel: UILabel!
    @IBOutlet private weak var maxTemperatureLabel: UILabel!
    
    @IBOutlet private weak var additionalWeatherInfoLabel: UILabel!
    
    @IBOutlet private weak var furtherWeatherStackView: UIStackView!
    @IBOutlet private var furtherWeatherLabels: [UILabel]!
    @IBOutlet private var furtherWeatherImageViews: [UIImageView]!
    @IBOutlet private var furtherWeatherlevelLabels: [UILabel]!
    @IBOutlet private var furtherWeatherIndicatorLabels: [UILabel]!
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(DisplayWeatherTemplate.self, from: payloadData) else { return }
            
            titleLabel.text = displayItem.title.text.text
            titleLabel.textColor = UIColor.textColor(rgbHexString: displayItem.title.text.color)
            
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
            
            if let logoUrl = displayItem.title.logo?.sources.first?.url {
                logoImageView.loadImage(from: logoUrl)
                logoImageView.isHidden = false
            } else {
                logoImageView.isHidden = true
            }

            // Set location info
            locationButton.setTitle(displayItem.title.subtext?.text, for: .normal)
            locationButton.setTitleColor(UIColor.textColor(rgbHexString: displayItem.title.subtext?.color), for: .normal)
            
            // Set weather info and image
            weatherLabel.text = displayItem.content.header?.text ?? "-"
            weatherLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.header?.color)
            
            if let contentUrl = displayItem.content.image?.sources.first?.url {
                weatherImageView.loadImage(from: contentUrl)
            } else {
                weatherImageView.image = nil
            }
            
            // Set tempertature infos
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
            
            // Set additional weather infos with html typed string
            if let bodyTextData = displayItem.content.body?.text.data(using: .utf8),
                let attributedBodyText = try? NSAttributedString(
                    data: bodyTextData,
                    options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                    documentAttributes: nil
                ) {
                additionalWeatherInfoLabel.attributedText = attributedBodyText
                additionalWeatherInfoLabel.textAlignment = .center
            } else {
                additionalWeatherInfoLabel.text = displayItem.content.body?.text
                additionalWeatherInfoLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.body?.color)
            }
            
            // Set detail ui by min/max temperature existence
            if (minTemperatureLabel.text == nil) || (maxTemperatureLabel.text == nil) {
                temperatureStackView.isHidden = true
                additionalWeatherInfoLabel.font = .systemFont(ofSize: 24)
            } else {
                temperatureStackView.isHidden = false
                additionalWeatherInfoLabel.font = .systemFont(ofSize: 16)
            }
            
            // Set further weather infos and images
            furtherWeatherStackView.arrangedSubviews.forEach { $0.isHidden = true }
            displayItem.content.listItems?.enumerated().forEach({ (index, item) in
                if furtherWeatherStackView.arrangedSubviews.indices.contains(index) {
                    furtherWeatherLabels[index].text = item.header?.text
                    furtherWeatherLabels[index].textColor = UIColor.textColor(rgbHexString: item.header?.color)
                
                    if let weatherIconUrl = item.image?.sources.first?.url {
                        furtherWeatherImageViews[index].loadImage(from: weatherIconUrl)
                    } else {
                        furtherWeatherImageViews[index].image = nil
                    }
                    
                    if let bodyTextData = item.body?.text.data(using: .utf8),
                        let attributedBodyText = try? NSAttributedString(
                            data: bodyTextData,
                            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                            documentAttributes: nil
                        ) {
                        furtherWeatherlevelLabels[index].attributedText = attributedBodyText
                        furtherWeatherlevelLabels[index].textAlignment = .center
                    } else {
                        furtherWeatherlevelLabels[index].text = item.body?.text
                        furtherWeatherlevelLabels[index].textColor = UIColor.textColor(rgbHexString: item.body?.color)
                    }
                    
                    furtherWeatherIndicatorLabels[index].text = item.footer?.text
                    furtherWeatherIndicatorLabels[index].textColor = UIColor.textColor(rgbHexString: item.footer?.color)
                }
                furtherWeatherStackView.arrangedSubviews[index].isHidden = false
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
        weatherImageView.layer.cornerRadius = 4.0
        weatherImageView.clipsToBounds = true
    }
}
