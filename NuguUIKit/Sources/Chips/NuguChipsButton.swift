//
//  NuguChipsButton.swift
//  NuguUIKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/04/23.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
//

import UIKit

final public class NuguChipsButton: UIButton {
    
    // MARK: - NuguChipsButton.Const
    
    private struct ChipsButtonConst {
        static let chipsInset = CGFloat(16.0)
        static let chipsHeight = CGFloat(40.0)
        static let chipsFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
    }
    
    // MARK: - NuguChipsButton.NuguChipsButtonTheme
    
    public enum NuguChipsButtonTheme {
        case light
        case dark
        
        var backgroundColor: UIColor {
            switch self {
            case .light:
                return UIColor(red: 239.0/255.0, green: 240.0/255.0, blue: 242.0/255.0, alpha: 1.0)
            case .dark:
                return UIColor(red: 55.0/255.0, green: 68.0/255.0, blue: 78.0/255.0, alpha: 1.0)
            }
        }
        
        var highlightedBackgroundColor: UIColor {
            switch self {
            case .light:
                return UIColor(red: 214.0/255.0, green: 215.0/255.0, blue: 217.0/255.0, alpha: 1.0)
            case .dark:
                return UIColor(red: 75.0/255.0, green: 87.0/255.0, blue: 96.0/255.0, alpha: 1.0)
            }
        }
    }
    
    // MARK: - NuguChipsButton.NuguChipsButtonType
    
    public enum NuguChipsButtonType {
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
        
        func textColor(theme: NuguChipsButtonTheme) -> UIColor {
            switch (self, theme) {
            case (.action, .light):
                return UIColor(red: 0.0/255.0, green: 157.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            case (.action, .dark):
                return UIColor(red: 85.0/255.0, green: 190.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            case (.normal, .light):
                return UIColor(red: 64.0/255.0, green: 72.0/255.0, blue: 88.0/255.0, alpha: 1.0)
            case (.normal, .dark):
                return .white
            }
        }
    }
    
    // MARK: Private Properties
    
    private var theme: NuguChipsButtonTheme = .light
    private var type: NuguChipsButtonType = .normal(text: "")
    
    // MARK: Override
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(theme: NuguChipsButtonTheme, type: NuguChipsButtonType) {
        self.init(type: .custom)
        
        self.theme = theme
        self.type = type
        
        titleLabel?.lineBreakMode = .byTruncatingTail
        contentEdgeInsets = UIEdgeInsets(top: 0, left: ChipsButtonConst.chipsInset, bottom: 0, right: ChipsButtonConst.chipsInset)
        layer.cornerRadius = ChipsButtonConst.chipsHeight / 2
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.04).cgColor
        clipsToBounds = true
        backgroundColor = theme.backgroundColor
        setTitleColor(type.textColor(theme: theme), for: .normal)
        setTitle(type.text, for: .normal)
        titleLabel?.font = ChipsButtonConst.chipsFont
    }
    
    override public var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? theme.highlightedBackgroundColor : theme.backgroundColor
        }
    }
}
