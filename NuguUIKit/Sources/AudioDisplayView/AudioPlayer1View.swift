//
//  AudioPlayer1View.swift
//  NuguUIKit
//
//  Created by yonghoonKwon on 20/07/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
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

final class AudioPlayer1View: AudioDisplayView {
    // Private Properties
    @IBOutlet private weak var contentStackView: UIStackView!
    
    @IBOutlet private weak var lyricsView: UIView!
    @IBOutlet private weak var currentLyricsLabel: UILabel!
    @IBOutlet private weak var nextLyricsLabel: UILabel!
    
    @IBOutlet private weak var badgeImageView: UIImageView!
    @IBOutlet private weak var badgeLabel: UILabel!
    
    private var lyricsTimer: DispatchSourceTimer?
    private let lyricsTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.AudioPlayer1View.lyrics")
    private var lyricsData: AudioPlayerLyricsTemplate?
    private var lyricsIndex = 0
    
    private var fullLyricsView: FullLyricsView?
    
    // Public Properties
    public override var isLyricsVisible: Bool {
        return !lyricsView.isHidden
    }
    
    override var displayPayload: [String: AnyHashable]? {
        didSet {
            guard let displayPayload = displayPayload,
                let payloadData = try? JSONSerialization.data(withJSONObject: displayPayload, options: []),
                let displayItem = try? JSONDecoder().decode(AudioPlayer1Template.self, from: payloadData) else { return }
            
            let template = displayItem.template
            
            titleView.setData(logoUrl: template.title.iconUrl, titleText: template.title.text)
            
            albumImageView.loadImage(from: template.content.imageUrl)
            titleLabel.text = template.content.title
            subtitle1Label.text = template.content.subtitle1
            subtitle2Label.text = template.content.subtitle2
            
            badgeImageView.isHidden = template.content.badgeImageUrl == nil
            badgeImageView.loadImage(from: template.content.badgeImageUrl)
            badgeLabel.text = template.content.badgeMessage
            
            lyricsData = template.content.lyrics
            lyricsView.isHidden = lyricsData?.lyricsType == .none
            lyricsView.gestureRecognizers?.forEach { lyricsView.removeGestureRecognizer($0) }
            let tapGestureRecognizeView = UITapGestureRecognizer(target: self, action: #selector(lyricsViewDidTap(_:)))
            lyricsView.addGestureRecognizer(tapGestureRecognizeView)
            
            if let favorite = template.content.settings?.favorite {
                favoriteButtonContainerView.isHidden = false
                favoriteButton.isSelected = favorite
            } else {
                favoriteButtonContainerView.isHidden = true
            }
            
            if let `repeat` = template.content.settings?.repeat {
                repeatButton.isHidden = false
                repeatMode = `repeat`
            } else {
                repeatButton.isHidden = true
            }
            
            if let shuffle = template.content.settings?.shuffle {
                shuffleButton.isHidden = false
                shuffleButton.isSelected = shuffle
            } else {
                shuffleButton.isHidden = true
            }
            
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
                bodyText: template.content.subtitle1
            )
        }
    }
    
    // Initialize
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
        let view = Bundle(for: AudioPlayer1View.self).loadNibNamed("AudioPlayer1View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        albumImageView.layer.cornerRadius = 8.0
        
        albumImageViewShadowView.layer.shadowColor = UIColor.black.cgColor
        albumImageViewShadowView.layer.shadowOpacity = 0.5
        albumImageViewShadowView.layer.shadowOffset = CGSize(width: 0, height: 5)
        albumImageViewShadowView.layer.shadowRadius = 5
        
        badgeImageView.layer.cornerRadius = badgeImageView.frame.size.height/2
        badgeImageView.layer.borderColor = UIColor(red: 1, green: 58.0/255.0, blue: 0, alpha: 1.0).cgColor
        badgeImageView.layer.borderWidth = 1.5
        
        badgeLabel.layer.cornerRadius = 2.0
        badgeLabel.clipsToBounds = true
        
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
    }
    
    // MARK: - Show / Hide lyrics
    
    override func shouldShowLyrics() -> Bool {
        showLyrics()
        return true
    }
    
    override func shouldHideLyrics() -> Bool {
        fullLyricsView?.removeFromSuperview()
        return true
    }
    
    override func startProgressTimer() {
        super.startProgressTimer()
        
        lyricsTimer?.cancel()
        lyricsTimer = DispatchSource.makeTimerSource(queue: lyricsTimerQueue)
        lyricsTimer?.schedule(deadline: .now(), repeating: 0.1)
        lyricsTimer?.setEventHandler(handler: { [weak self] in
            self?.updateLyrics()
        })
        lyricsTimer?.resume()
    }
    
    override func stopProgressTimer() {
        super.stopProgressTimer()
        
        lyricsTimer?.cancel()
        lyricsTimer = nil
    }
}

// MARK: - Private (Selector)

private extension AudioPlayer1View {
    @objc func lyricsViewDidTap(_ gestureRecognizer: UITapGestureRecognizer) {
        showLyrics()
    }
}

// MARK: - Private (Lyrics)

private extension AudioPlayer1View {
    func showLyrics() {
        fullLyricsView = FullLyricsView(frame: contentStackView.frame)
        fullLyricsView?.headerLabel.text = lyricsData?.title
        lyricsData?.lyricsInfoList.forEach { lyricsInfo in
            let label = UILabel()
            label.textAlignment = .center
            label.text = lyricsInfo.text
            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = UIColor(red: 68.0/255.0, green: 68.0/255.0, blue: 68.0/255.0, alpha: 1.0)
            fullLyricsView?.stackView.addArrangedSubview(label)
        }
        fullLyricsView?.onViewDidTap = { [weak self] in
            self?.fullLyricsView?.removeFromSuperview()
        }
        if let fullLyricsView = fullLyricsView {
            fullAudioPlayerContainerView.addSubview(fullLyricsView)
        }
        if self.lyricsIndex != -1 {
            fullLyricsView?.updateLyricsFocus(lyricsIndex: self.lyricsIndex)
        }
    }
    
    func updateLyrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let lyricsInfoList = self.lyricsData?.lyricsInfoList,
                  let offSet = self.delegate?.requestOffset(),
                self.lyricsData?.lyricsType != "NONE" else {
                    self.lyricsView.isHidden = true
                    return
            }
            
            self.lyricsView.isHidden = false
            
            if self.lyricsData?.lyricsType == "NON_SYNC" {
                self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
                self.currentLyricsLabel.text = "전체 가사보기"
                self.nextLyricsLabel.text = nil
                return
            }
            
            let currentOffSetInMilliseconds = offSet * 1000
            
            guard let firstStartTime = lyricsInfoList.first?.time else { return }
            if currentOffSetInMilliseconds < firstStartTime && self.lyricsIndex != -1 {
                self.lyricsIndex = -1
                self.currentLyricsLabel.textColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1.0)
                self.currentLyricsLabel.text = lyricsInfoList.first?.text
                self.nextLyricsLabel.text = lyricsInfoList[1].text
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: nil)
                return
            }
            
            guard let lastStartTime = lyricsInfoList.last?.time else { return }
            if currentOffSetInMilliseconds >= lastStartTime && self.lyricsIndex != lyricsInfoList.count - 1 {
                self.lyricsIndex = lyricsInfoList.count - 1
                self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
                self.currentLyricsLabel.text = lyricsInfoList.last?.text
                self.nextLyricsLabel.text = ""
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: lyricsInfoList.count - 1)
                return
            }
            
            guard let nextLyricsIndex = lyricsInfoList.firstIndex(where: { (lyricsInfo) -> Bool in
                guard let lyricsTime = lyricsInfo.time else { return false }
                return currentOffSetInMilliseconds < lyricsTime
            }) else { return }
            let currentLyricsIndex = nextLyricsIndex - 1
            guard self.lyricsIndex != currentLyricsIndex else { return }
            self.lyricsIndex = currentLyricsIndex
                                    
            self.fullLyricsView?.updateLyricsFocus(lyricsIndex: currentLyricsIndex)  
            self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
            self.currentLyricsLabel.text = lyricsInfoList[currentLyricsIndex].text
            self.nextLyricsLabel.text = lyricsInfoList[nextLyricsIndex].text
            
            self.fullLyricsView?.updateLyricsFocus(lyricsIndex: currentLyricsIndex)
        }
    }
}
