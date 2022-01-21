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

import NuguAgents

final class DisplayTitleView: UIView {
    @IBOutlet weak var titleContainerView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
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
        #if DEPLOY_OTHER_PACKAGE_MANAGER
        let view = Bundle(for: DisplayTitleView.self).loadNibNamed("DisplayTitleView", owner: self)?.first as! UIView
        #else
        let view = Bundle.module.loadNibNamed("DisplayTitleView", owner: self)?.first as! UIView
        #endif
        // swiftlint:enable force_cast
        insertSubview(view, at: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        backgroundColor = .clear
        
        closeButton.setImage(UIImage(named: "btn_close", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
    }
    
    func setData(titleData: DisplayCommonTemplate.Common.Title) {
        // Set title
        logoImageView.loadImage(
            from: titleData.logo?.sources.first?.url,
            failureImage: UIImage(named: "nugu_logo_default", in: Bundle.imageBundle, compatibleWith: nil)
        )
        titleLabel.setDisplayText(displayText: titleData.text)
    }
    
    func setData(logoUrl: String?, titleText: String) {
        // Set title
        logoImageView.loadImage(
            from: logoUrl,
            failureImage: UIImage(named: "nugu_logo_default", in: Bundle.imageBundle, compatibleWith: nil)
        )
        titleLabel.text = titleText
    }
    
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
}
