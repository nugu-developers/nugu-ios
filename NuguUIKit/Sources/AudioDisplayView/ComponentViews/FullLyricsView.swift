//
//  FullLyricsView.swift
//  NuguUIKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/21.
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

final class FullLyricsView: UIView {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    var onViewDidTap: (() -> Void)?
    
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
        let view = Bundle(for: FullLyricsView.self).loadNibNamed("FullLyricsView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap(gestureRecognizer:)))
        addGestureRecognizer(tapRecognizer)
    }
    
    func updateLyricsFocus(lyricsIndex: Int?) {
        stackView.arrangedSubviews.forEach { (label) in
            guard let label = label as? UILabel else { return }
            label.textColor = UIColor(red: 68.0/255.0, green: 68.0/255.0, blue: 68.0/255.0, alpha: 1.0)
        }
        guard let lyricsIndex = lyricsIndex,
            let currentLyricsLabel = stackView.arrangedSubviews[lyricsIndex + 1] as? UILabel else { return }
        currentLyricsLabel.textColor = UIColor(red: 0, green: 157.0/255.0, blue: 1, alpha: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.scrollView.scrollRectToVisible(currentLyricsLabel.frame, animated: true)
        }
    }
    
    @objc func viewDidTap(gestureRecognizer: UITapGestureRecognizer) {
        onViewDidTap?()
    }
}
