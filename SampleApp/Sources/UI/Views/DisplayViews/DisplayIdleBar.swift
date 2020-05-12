//
//  DisplayIdleBar.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/12.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
//

import UIKit

import NuguUIKit

final class DisplayIdleBar: UIView {
    @IBOutlet private weak var nuguButton: NuguButton!
    @IBOutlet private weak var chipsView: NuguChipsView!
    
    var onNuguButtonClick: (() -> Void)?
    
    var onChipsSelect: ((_ text: String?) -> Void)? {
        didSet {
            chipsView.onChipsSelect = onChipsSelect
        }
    }
    
    var chipsData: [NuguChipsButton.NuguChipsButtonType] = [] {
        didSet {
            chipsView.chipsData = chipsData
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
        let view = Bundle.main.loadNibNamed("DisplayIdleBar", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        backgroundColor = .clear
        nuguButton.addTarget(self, action: #selector(nuguButtonDidClick(button:)), for: .touchUpInside)
    }
    
    @objc func nuguButtonDidClick(button: NuguButton) {
        onNuguButtonClick?()
    }
}
