//
//  DisplayTitleView.swift
//  NuguUIKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/15.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

final class DisplayTitleView: UIView {
    @IBOutlet weak var titleContainerView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var onCloseButtonClick: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromXib()
    }
    
    func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle(for: DisplayTitleView.self).loadNibNamed("DisplayTitleView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = CGRect(origin: view.frame.origin, size: CGSize(width: UIScreen.main.bounds.size.width, height: view.frame.size.height))
        addSubview(view)
        backgroundColor = .clear
    }
    
    func setData(titleData: DisplayCommonTemplate.Common.Title) {
        // Set title
        if let logoUrl = titleData.logo?.sources.first?.url {
            logoImageView.loadImage(from: logoUrl)
            logoImageView.isHidden = false
        } else {
            logoImageView.isHidden = true
        }
        titleLabel.setDisplayText(displayText: titleData.text)
    }
    
    func setData(logoUrl: String?, titleText: String) {
        // Set title
        if let logoUrl = logoUrl {
            logoImageView.loadImage(from: logoUrl)
            logoImageView.isHidden = false
        } else {
            logoImageView.isHidden = true
        }
        titleLabel.text = titleText
    }
    
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
}
