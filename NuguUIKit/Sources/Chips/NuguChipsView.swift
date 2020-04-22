//
//  NuguChipsView.swift
//  NuguUIKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/04/22.
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

final public class NuguChipsView: UIView {
    private struct ChipsConst {
        static let scrollViewOriginX = CGFloat(14.0)
        static let scrollViewOriginY = CGFloat(14.0)
        static let chipsInset = CGFloat(16.0)
        static let chipsHeight = CGFloat(40.0)
        static let spaceBetweenChips = CGFloat(8.0)
        static let chipsFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        static let minChipsCount = 2
        static let maxChipsCount = 10
        static let maxChipsWidth = UIScreen.main.bounds.size.width - CGFloat(180.0)
    }
    
    // MARK: - NuguChipsView.NuguChipsViewTheme
    
    public enum NuguChipsViewTheme {
        case black
        case white
        
        var chipsBackgroundColor: UIColor {
            switch self {
            case .black:
                return UIColor(red: 55.0/255.0, green: 68.0/255.0, blue: 78.0/255.0, alpha: 1.0)
            case .white:
                return UIColor(red: 239.0/255.0, green: 240.0/255.0, blue: 242.0/255.0, alpha: 1.0)
            }
        }
    }
    
    // MARK: - NuguChipsView.NuguChipsType
    
    public enum NuguChipsType {
        case action(text: String)
        case normal(text: String)
        
        var text: String {
            switch self {
            case .action(let text):
                return text
            case .normal(let text):
                return text
            }
        }
        
        func textColor(theme: NuguChipsViewTheme) -> UIColor {
            switch (self, theme) {
            case (.action, .white):
                return UIColor(red: 0.0/255.0, green: 157.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            case (.action, .black):
                return UIColor(red: 85.0/255.0, green: 190.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            case (.normal, .white):
                return UIColor(red: 64.0/255.0, green: 72.0/255.0, blue: 88.0/255.0, alpha: 1.0)
            case (.normal, .black):
                return .white
            }
        }
    }
    
    // MARK: - Public Properties (configurable variables)
    
    public var theme: NuguChipsViewTheme = .white
    
    public var onChipsSelect: ((_ text: String?) -> Void)?
    
    public var willStartScrolling: (() -> Void)?
    
    public var chipsText: [NuguChipsType] = [] {
        didSet {
            guard chipsText.count >= ChipsConst.minChipsCount else { return }
            var origin = CGPoint(x: ChipsConst.scrollViewOriginX, y: ChipsConst.scrollViewOriginY)
            chipsText.enumerated().forEach { (index, chipsType) in
                guard index < ChipsConst.maxChipsCount else { return }
                let chipsButton = UIButton(type: .custom)
                chipsButton.titleLabel?.lineBreakMode = .byTruncatingTail
                chipsButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: ChipsConst.chipsInset, bottom: 0, right: ChipsConst.chipsInset)
                chipsButton.layer.cornerRadius = ChipsConst.chipsHeight / 2
                chipsButton.layer.borderWidth = 0.5
                chipsButton.layer.borderColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.04).cgColor
                chipsButton.clipsToBounds = true
                chipsButton.backgroundColor = theme.chipsBackgroundColor
                chipsButton.setTitleColor(chipsType.textColor(theme: theme), for: .normal)
                chipsButton.setTitle(chipsType.text, for: .normal)
                chipsButton.titleLabel?.font = ChipsConst.chipsFont
                chipsButton.addTarget(self, action: #selector(chipsDidSelect(button:)), for: .touchUpInside)
                chipsButton.sizeToFit()
                chipsButton.frame = CGRect(origin: origin, size: CGSize(width: min(chipsButton.frame.size.width, ChipsConst.maxChipsWidth), height: ChipsConst.chipsHeight))
                origin = CGPoint(x: origin.x + ChipsConst.spaceBetweenChips + chipsButton.frame.size.width, y: origin.y)
                chipsScrollView.addSubview(chipsButton)
                chipsScrollView.contentSize = CGSize(width: origin.x, height: ChipsConst.chipsHeight)
            }
        }
    }
    
    // MARK: Private Properties
    
    @IBOutlet private weak var chipsScrollView: UIScrollView!
    
    // MARK: Override
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromXib()
    }
    
    private func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle(for: NuguVoiceChrome.self).loadNibNamed("NuguChipsView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        chipsScrollView.delegate = self
    }
}

// MARK: - UIScrollViewDelegate

extension NuguChipsView: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        willStartScrolling?()
    }
}

// MARK: - Target / Action

@objc extension NuguChipsView {
    func chipsDidSelect(button: UIButton) {
        onChipsSelect?(button.titleLabel?.text)
    }
}
