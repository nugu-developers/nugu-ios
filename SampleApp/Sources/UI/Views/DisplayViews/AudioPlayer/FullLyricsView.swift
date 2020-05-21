//
//  FullLyricsView.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/21.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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
        let view = Bundle.main.loadNibNamed("FullLyricsView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap(gestureRecognizer:)))
        addGestureRecognizer(tapRecognizer)
    }
    
    func updateLyricsFocus(lyricsIndex: Int) {
        guard let currentLyricsLabel = stackView.arrangedSubviews[lyricsIndex+1] as? UILabel
            else { return }
        if let prevLyricsLabel = stackView.arrangedSubviews[lyricsIndex] as? UILabel {
            prevLyricsLabel.textColor = UIColor(red: 68.0/255.0, green: 68.0/255.0, blue: 68.0/255.0, alpha: 1.0)
        }
        currentLyricsLabel.textColor = UIColor(red: 0, green: 157.0/255.0, blue: 1, alpha: 1.0)
    }
    
    @objc func viewDidTap(gestureRecognizer: UITapGestureRecognizer) {
        onViewDidTap?()
    }
}
