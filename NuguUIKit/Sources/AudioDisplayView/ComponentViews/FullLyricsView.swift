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
    @IBOutlet weak var noLyricsLabel: UILabel!
    
    var onViewDidTap: (() -> Void)?
    
    private var isScrolling = false
    private var currentIndex: Int?
    
    var theme: AudioDisplayTheme = .light {
        didSet {
            backgroundColor = theme.backgroundColor
            scrollView.backgroundColor = theme.backgroundColor
            stackView.backgroundColor = theme.backgroundColor
            headerLabel.textColor = theme.fullLyricsHeaderLabelTextColor
            updateLyricsFocus(lyricsIndex: currentIndex)
        }
    }
    
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
        let view = Bundle(for: FullLyricsView.self).loadNibNamed("FullLyricsView", owner: self)?.first as! UIView
        #else
        let view = Bundle.module.loadNibNamed("FullLyricsView", owner: self)?.first as! UIView
        #endif
        // swiftlint:enable force_cast
        addSubview(view)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap(gestureRecognizer:)))
        addGestureRecognizer(tapRecognizer)
        scrollView.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    func updateLyricsFocus(lyricsIndex: Int?) {
        guard isHidden == false else { return }
        currentIndex = lyricsIndex
        stackView.arrangedSubviews.forEach { (label) in
            guard let label = label as? UILabel else { return }
            label.textColor = theme.fullLyricsLabelTextColor
        }
        guard let lyricsIndex = lyricsIndex,
              lyricsIndex < stackView.arrangedSubviews.count - 1,
            let currentLyricsLabel = stackView.arrangedSubviews[lyricsIndex + 1] as? UILabel else { return }
        currentLyricsLabel.textColor = UIColor(red: 0, green: 157.0/255.0, blue: 1, alpha: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self,
                  self.isScrolling == false else { return }
            if currentLyricsLabel.frame.origin.y - self.scrollView.frame.size.height/2 < 0 {
                self.scrollView.setContentOffset(.zero, animated: true)
            } else {
                let scrollOffset = CGPoint(x: currentLyricsLabel.frame.origin.x, y: currentLyricsLabel.frame.origin.y - self.scrollView.frame.size.height/2)
                self.scrollView.setContentOffset(scrollOffset, animated: true)
            }
        }
    }
    
    @objc func viewDidTap(gestureRecognizer: UITapGestureRecognizer) {
        onViewDidTap?()
    }
}

extension FullLyricsView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            isScrolling = false
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrolling = false
    }
}
