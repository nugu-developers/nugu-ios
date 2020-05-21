//
//  Weather1View.swift
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

final class Weather1View: DisplayView {
    
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
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(Weather1Template.self, from: payloadData) else { return }
            
            // Set backgroundColor
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
                        
            // Set title
            titleView.setData(titleData: displayItem.title)
            titleView.onCloseButtonClick = { [weak self] in
                self?.onCloseButtonClick?()
            }
            
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
            additionalWeatherInfoLabel.setAttributedDisplayText(displayText: displayItem.content.body)
            
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
                }
                furtherWeatherStackView.arrangedSubviews[index].isHidden = false
            })
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("Weather1View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
    }
}
