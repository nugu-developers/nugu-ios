//
//  Weather2View.swift
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

final class Weather2View: DisplayView {
    
    @IBOutlet private weak var contentImageViewContainerView: UIView!
    @IBOutlet private weak var contentImageView: UIImageView!
    
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    
    @IBOutlet private weak var furtherWeatherStackView: UIStackView!
    @IBOutlet private var furtherWeatherLabels: [UILabel]!
    @IBOutlet private var furtherWeatherImageViews: [UIImageView]!
    @IBOutlet private var furtherWeatherlevelLabels: [UILabel]!
    @IBOutlet private var furtherWeatherIndicatorLabels: [UILabel]!
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(Weather2Template.self, from: payloadData) else { return }
            
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
                switch buttonItem.eventType {
                case .elementSelected:
                    contentButtonEventType = .elementSelected(token: buttonItem.token, postback: buttonItem.postback)
                case .textInput:
                    contentButtonEventType = .textInput(textInput: buttonItem.textInput)
                default:
                    break
                }
            } else {
                contentButtonContainerView.isHidden = true
            }
            
            // Set weather info and image
            headerLabel.text = displayItem.content.header?.text ?? "-"
            headerLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.header?.color)
            
            // Set content image
            if let contentUrl = displayItem.content.image?.sources.first?.url {
                contentImageView.loadImage(from: contentUrl)
                contentImageViewContainerView.isHidden = false
            } else {
                contentImageViewContainerView.isHidden = true
            }
            
            // Set additional weather infos with html typed string
            bodyLabel.setAttributedDisplayText(displayText: displayItem.content.body)
            
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
                    
                    if let bodyTextData = item.body?.text?.data(using: .utf8),
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
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("Weather2View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
    }
}
