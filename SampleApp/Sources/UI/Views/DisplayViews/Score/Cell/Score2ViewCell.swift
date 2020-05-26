//
//  Score2ViewCell.swift
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

final class Score2ViewCell: UITableViewCell {
    @IBOutlet private weak var whiteBackgroundView: UIView!
    
    @IBOutlet private weak var scheduleLabel: UILabel!
    
    @IBOutlet private weak var leftScoreImageView: UIImageView!
    @IBOutlet private weak var leftScoreHeaderLabel: UILabel!
    @IBOutlet private weak var leftScoreBodyLabel: UILabel!
    
    @IBOutlet private weak var rightScoreImageView: UIImageView!
    @IBOutlet private weak var rightScoreHeaderLabel: UILabel!
    @IBOutlet private weak var rightScoreBodyLabel: UILabel!
    
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var scoreLabel: UILabel!
    
    func configure(item: Score2Template.Item?) {
        if item == nil { return }
        
        whiteBackgroundView.clipsToBounds = true
        whiteBackgroundView.layer.cornerRadius = 8.0
        whiteBackgroundView.layer.borderColor = UIColor(red: 236.0/255.0, green: 236.0/255.0, blue: 236.0/255.0, alpha: 1.0).cgColor
        whiteBackgroundView.layer.borderWidth = 1.0
        
        // Set status label
        scheduleLabel.setDisplayText(displayText: item?.schedule)
                                
        // Set match views
        leftScoreImageView.clipsToBounds = true
        leftScoreImageView.layer.cornerRadius = 2.0
        leftScoreImageView.loadImage(from: item?.match[0].image.sources.first?.url)
        leftScoreHeaderLabel.setDisplayText(displayText: item?.match[0].header)
        leftScoreBodyLabel.setDisplayText(displayText: item?.match[0].body)
        
        rightScoreImageView.clipsToBounds = true
        rightScoreImageView.layer.cornerRadius = 2.0
        rightScoreImageView.loadImage(from: item?.match[1].image.sources.first?.url)
        rightScoreHeaderLabel.setDisplayText(displayText: item?.match[1].header)
        rightScoreBodyLabel.setDisplayText(displayText: item?.match[1].body)
        
        // Set score label
        scoreLabel.text = (item?.match[0].score.text ?? "-") + " : " + (item?.match[1].score.text ?? "-")
        
        // Set status label
        statusLabel.text = item?.status.text
        statusLabel.layer.cornerRadius = statusLabel.bounds.size.height/2
        statusLabel.layer.borderColor = UIColor(red: 151/255.0, green: 151/255.0, blue: 151/255.0, alpha: 1.0).cgColor
        statusLabel.layer.borderWidth = 0.5
    }
}
