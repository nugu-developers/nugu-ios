//
//  ImageList1ViewCell.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/18.
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

final class ImageList1ViewCell: UITableViewCell {
    @IBOutlet private weak var leftStackView: UIStackView!
    
    @IBOutlet private weak var leftNumberLabelContainerView: UIView!
    @IBOutlet private weak var leftNumberLabel: UILabel!
    @IBOutlet private weak var leftContentImageView: UIImageView!
    @IBOutlet private weak var leftHeaderLabel: UILabel!
    @IBOutlet private weak var leftFooterLabel: UILabel!
    
    @IBOutlet private weak var rightStackView: UIStackView!
    
    @IBOutlet private weak var rightNumberLabelContainerView: UIView!
    @IBOutlet private weak var rightNumberLabel: UILabel!
    @IBOutlet private weak var rightContentImageView: UIImageView!
    @IBOutlet private weak var rightContentStackView: UIStackView!
    @IBOutlet private weak var rightHeaderLabel: UILabel!
    @IBOutlet private weak var rightFooterLabel: UILabel!
    
    var onItemSelect: ((_ token: String?) -> Void)?
    private var leftItemToken: String?
    private var rightItemToken: String?
    
    func configure(badgeNumber: String?, leftItem: ImageList1Template.Item, rightItem: ImageList1Template.Item?) {
        leftItemToken = leftItem.token
        
        leftContentImageView.clipsToBounds = true
        leftContentImageView.layer.cornerRadius = 4.0
        leftContentImageView.loadImage(from: leftItem.image.sources.first?.url)
        
        leftNumberLabel.text = badgeNumber
        leftNumberLabelContainerView.isHidden = (badgeNumber == nil)
        
        leftHeaderLabel.setDisplayText(displayText: leftItem.header)
        leftFooterLabel.setDisplayText(displayText: leftItem.footer)
        
        leftStackView.gestureRecognizers?.forEach { [weak self] in self?.leftStackView.removeGestureRecognizer($0) }
        let leftTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onLeftItemDidClick))
        leftStackView.addGestureRecognizer(leftTapGestureRecognizer)
        
        guard let rightItem = rightItem else {
            rightStackView.isHidden = true
            rightContentImageView.isHidden = true
            rightItemToken = nil
            return
        }
        
        rightItemToken = rightItem.token
        rightStackView.isHidden = false
        rightContentImageView.isHidden = false
        
        rightContentImageView.clipsToBounds = true
        rightContentImageView.layer.cornerRadius = 4.0
        rightContentImageView.loadImage(from: leftItem.image.sources.first?.url)
        
        if let badgeNumber = badgeNumber,
            let badgeNumberAsInt = Int(badgeNumber) {
            rightNumberLabel.text = String(badgeNumberAsInt + 1)
        }
        rightNumberLabelContainerView.isHidden = (badgeNumber == nil)
        
        rightHeaderLabel.setDisplayText(displayText: leftItem.header)
        rightFooterLabel.setDisplayText(displayText: leftItem.footer)
        
        rightStackView.gestureRecognizers?.forEach { [weak self] in self?.rightStackView.removeGestureRecognizer($0) }
        let rightTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onRightItemDidClick))
        rightStackView.addGestureRecognizer(rightTapGestureRecognizer)
    }
    
    @objc func onLeftItemDidClick() {
        onItemSelect?(leftItemToken)
    }
    
    @objc func onRightItemDidClick() {
        onItemSelect?(rightItemToken)
    }
}
