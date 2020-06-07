//
//  Weather5View.swift
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

final class Weather5View: DisplayView {
    
    @IBOutlet private weak var headerLabel: UILabel!

    @IBOutlet private weak var graphView: UIView!
    
    @IBOutlet private weak var minLabel: UILabel!
    @IBOutlet private weak var maxLabel: UILabel!
    
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(Weather5Template.self, from: payloadData) else { return }
            
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
            
            headerLabel.text = displayItem.content.header?.text ?? "-"
            headerLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.header?.color)
            
            bodyLabel.text = displayItem.content.body?.text ?? "-"
            bodyLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.body?.color)
            
            footerLabel.text = displayItem.content.footer?.text ?? "-"
            footerLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.footer?.color)
            
            minLabel.text = displayItem.content.min?.text ?? "-"
            minLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.min?.color)
            
            maxLabel.text = displayItem.content.max?.text ?? "-"
            maxLabel.textColor = UIColor.textColor(rgbHexString: displayItem.content.max?.color)
            
            // Draw weather graph
            var progress = CGFloat(0)
            if let itemProgress = displayItem.content.progress,
                let progressInDouble = Double(itemProgress) {
                progress = CGFloat(progressInDouble)
            }
            let center = CGPoint(x: (UIScreen.main.bounds.width-40) / 2, y: graphView.frame.size.height - 20)
            let circleRadius = CGFloat(center.x - 28)
            let circlePath = UIBezierPath(arcCenter: center, radius: circleRadius, startAngle: .pi, endAngle: .pi*2, clockwise: true)
            
            let backgroundLayer = CAShapeLayer()
            backgroundLayer.path = circlePath.cgPath
            backgroundLayer.strokeColor = UIColor.gray.cgColor
            backgroundLayer.fillColor = UIColor.clear.cgColor
            backgroundLayer.lineDashPattern = [0, 16]
            backgroundLayer.lineWidth = 8
            backgroundLayer.strokeStart = 0
            backgroundLayer.strokeEnd  = 1
            graphView.layer.addSublayer(backgroundLayer)
            
            let graphLayer = CAShapeLayer()
            graphLayer.path = circlePath.cgPath
            graphLayer.strokeColor = UIColor(rgbHexString: displayItem.content.progressColor?.replacingOccurrences(of: "#", with: ""))?.cgColor
            graphLayer.fillColor = UIColor.clear.cgColor
            graphLayer.lineWidth = 8
            graphLayer.strokeStart = 0
            graphLayer.strokeEnd  = progress
            graphView.layer.addSublayer(graphLayer)
            
            let imagePositionPath = UIBezierPath(arcCenter: center, radius: circleRadius, startAngle: .pi, endAngle: .pi + (.pi*progress), clockwise: true)
            let clearLayer = CAShapeLayer()
            clearLayer.path = imagePositionPath.cgPath
            clearLayer.strokeStart = 0
            clearLayer.strokeEnd  = 1

            let iconImageView = UIImageView(frame: .zero)
            iconImageView.loadImage(from: displayItem.content.icon?.sources.first?.url)
            if let centerPoint = clearLayer.path?.currentPoint {
                iconImageView.center = centerPoint
                iconImageView.bounds = CGRect(origin: .zero, size: CGSize(width: 40, height: 40))
                graphView.addSubview(iconImageView)
            }

            // Set content button
            if let buttonItem = displayItem.title.button {
                contentButtonContainerView.isHidden = false
                contentButton.setTitle(buttonItem.text, for: .normal)
                contentButtonTokenAndPostback = (buttonItem.token, buttonItem.postback)
            } else {
                contentButtonContainerView.isHidden = true
            }
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("Weather5View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
    }
}
