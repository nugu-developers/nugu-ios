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
    
    // MARK: - NuguChipsView.Const
    
    private struct ChipsConst {
        static let scrollViewOriginX = CGFloat(14.0)
        static let scrollViewOriginY = CGFloat(14.0)
        static let spaceBetweenChips = CGFloat(8.0)
        static let chipsHeight = CGFloat(40.0)
        static let minChipsCount = 2
        static let maxChipsCount = 10
        static let maxChipsWidth = UIScreen.main.bounds.size.width - CGFloat(180.0)
    }
    
    // MARK: - NuguChipsView.NuguChipsViewTheme
    
    public enum NuguChipsViewTheme {
        case light
        case dark
    }
    
    // MARK: - Public Properties (configurable variables)
    
    public var onChipsSelect: ((_ text: String?) -> Void)?
    
    public var willStartScrolling: (() -> Void)?
    
    public var theme: NuguChipsViewTheme = .light
    
    public var chipsData: [NuguChipsButton.NuguChipsButtonType] = [] {
        didSet {
            chipsScrollView.subviews.forEach({ $0.removeFromSuperview() })
            guard chipsData.count >= ChipsConst.minChipsCount else { return }
            var origin = CGPoint(x: ChipsConst.scrollViewOriginX, y: ChipsConst.scrollViewOriginY)
            chipsData.enumerated().forEach { (index, chipsType) in
                guard index < ChipsConst.maxChipsCount else { return }
                let chipsButton = NuguChipsButton(theme: (self.theme == .light) ? .light : .dark, type: chipsType)
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
    func chipsDidSelect(button: NuguChipsButton) {
        onChipsSelect?(button.titleLabel?.text)
    }
}
