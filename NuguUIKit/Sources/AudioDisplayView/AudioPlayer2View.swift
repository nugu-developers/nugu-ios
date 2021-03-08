//
//  AudioPlayer2View.swift
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

final class AudioPlayer2View: AudioDisplayView {    
    // Intialize
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadFromXib()
    }
        
    private func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle(for: AudioPlayer2View.self).loadNibNamed("AudioPlayer2View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        albumImageView.layer.cornerRadius = 8.0
        
        albumImageViewShadowView.layer.shadowColor = UIColor.black.cgColor
        albumImageViewShadowView.layer.shadowOpacity = 0.5
        albumImageViewShadowView.layer.shadowOffset = CGSize(width: 0, height: 5)
        albumImageViewShadowView.layer.shadowRadius = 5

        titleView.onCloseButtonClick = { [weak self] in
            self?.delegate?.onCloseButtonClick()
        }
        idleBar.onChipsSelect = { [weak self] (selectedChips) in
            self?.delegate?.onChipsSelect(selectedChips: selectedChips)
        }
        idleBar.onNuguButtonClick = { [weak self] in
            self?.delegate?.onNuguButtonClick()
        }
        audioPlayerBarView.delegate = self
        
        barTypeButton.setImage(UIImage(named: "btn_down", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        favoriteButton.setImage(UIImage(named: "btn_like_off", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        favoriteButton.setImage(UIImage(named: "btn_like_on", in: Bundle.imageBundle, compatibleWith: nil), for: .selected)
        prevButton.setImage(UIImage(named: "btn_skip_previous", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        playPauseButton.setImage(UIImage(named: "btn_play", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        playPauseButton.setImage(UIImage(named: "btn_pause", in: Bundle.imageBundle, compatibleWith: nil), for: .selected)
        nextButton.setImage(UIImage(named: "btn_skip_next", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        shuffleButton.setImage(UIImage(named: "btn_random_off", in: Bundle.imageBundle, compatibleWith: nil), for: .normal)
        shuffleButton.setImage(UIImage(named: "btn_random_on", in: Bundle.imageBundle, compatibleWith: nil), for: .selected)
    }

    override var displayPayload: [String: AnyHashable]? {
        didSet {
            guard let displayPayload = displayPayload,
                let payloadData = try? JSONSerialization.data(withJSONObject: displayPayload, options: []),
                let displayItem = try? JSONDecoder().decode(AudioPlayer2Template.self, from: payloadData) else { return }
            
            let template = displayItem.template
            
            titleView.setData(logoUrl: template.title.iconUrl, titleText: template.title.text)
            
            albumImageView.loadImage(from: template.content.imageUrl)
            titleLabel.text = template.content.title
            subtitle1Label.text = template.content.subtitle
            subtitle2Label.text = template.content.subtitle1
            
            lyricsData = template.content.lyrics
            lyricsView.isHidden = lyricsData?.lyricsType == .none
            lyricsView.gestureRecognizers?.forEach { lyricsView.removeGestureRecognizer($0) }
            let tapGestureRecognizeView = UITapGestureRecognizer(target: self, action: #selector(lyricsViewDidTap(_:)))
            lyricsView.addGestureRecognizer(tapGestureRecognizeView)
            updateLyrics()
            replaceFullLyrics()
            
            favoriteButtonContainerView.isHidden = true
            repeatButton.isHidden = true
            shuffleButton.isHidden = true
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = template.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            if isSeekable {
                startProgressTimer()
            } else {
                stopProgressTimer()
                elapsedTimeLabel.text = nil
                durationTimeLabel.text = nil
                progressView.isHidden = true
            }
            
            playPauseButton.isSelected = delegate?.requestAudioPlayerIsPlaying() == true
            audioPlayerBarView.playPauseButton.isSelected = delegate?.requestAudioPlayerIsPlaying() == true
            
            audioPlayerBarView.setData(
                imageUrl: template.content.imageUrl,
                headerText: template.content.title,
                bodyText: template.content.subtitle
            )
        }
    }
    
    override func updateLyrics() {
        super.updateLyrics()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.lyricsData?.lyricsType != "NONE" else {
                self.lyricsView.isHidden = true
                return
            }
            
            self.lyricsView.isHidden = false
                        
            if self.lyricsData?.lyricsType == "NON_SYNC" {
                self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
                if let showButtonText = self.lyricsData?.showButton?.text {
                    self.currentLyricsLabel.text = showButtonText
                } else {
                    self.currentLyricsLabel.text = "요약문 보기"
                }
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: nil)
                return
            }
        }
    }
}
