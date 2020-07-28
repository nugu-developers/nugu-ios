//
//  AudioPlayer1View.swift
//  SampleApp
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

import NuguAgents
import NuguUIKit

final class AudioPlayer1View: AudioDisplayView {
    
    // MARK: Properties
    
    @IBOutlet private weak var contentStackView: UIStackView!
    
    @IBOutlet private weak var lyricsView: UIView!
    @IBOutlet private weak var currentLyricsLabel: UILabel!
    @IBOutlet private weak var nextLyricsLabel: UILabel!
    
    @IBOutlet private weak var badgeImageView: UIImageView!
    @IBOutlet private weak var badgeLabel: UILabel!
    
    private var audioProgressTimer: DispatchSourceTimer?
    private let audioProgressTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.AudioPlayer1View.audioProgress")
    
    private var lyricsTimer: DispatchSourceTimer?
    private let lyricsTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.AudioPlayer1View.lyrics")
    private var lyricsData: AudioPlayerLyricsTemplate?
    private var lyricsIndex = 0
    
    private var fullLyricsView: FullLyricsView?
    
    override var isLyricsVisible: Bool {
        return !lyricsView.isHidden
    }
    
    override var displayPayload: [String: AnyHashable]? {
        didSet {
            guard let displayPayload = displayPayload,
                let payloadData = try? JSONSerialization.data(withJSONObject: displayPayload, options: []),
                let displayItem = try? JSONDecoder().decode(AudioPlayer1Template.self, from: payloadData) else { return }
            
            let template = displayItem.template
            
            titleView.setData(logoUrl: template.title.iconUrl, titleText: template.title.text)
            titleView.onCloseButtonClick = { [weak self] in
                self?.onCloseButtonClick?()
            }
            
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
                
            audioPlayerBarView.setData(
                imageUrl: template.content.imageUrl,
                headerText: template.content.title,
                bodyText: template.content.subtitle1
            )
            audioPlayerBarView.onCloseButtonClick = { [weak self] in
                self?.onCloseButtonClick?()
            }
            audioPlayerBarView.onViewDidTap = { [weak self] in
                UIView.animate(withDuration: 0.3) { [weak self] in
                    guard let self = self else { return }
                    self.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: UIScreen.main.bounds.size)
                    self.fullAudioPlayerContainerView.isHidden = false
                    self.audioPlayerBarViewContainerView.isHidden = true
                }
            }
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
    
    private func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("AudioPlayer1View", owner: self)?.first as! UIView
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
    
    private func showLyrics() {
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
    }
}

// MARK: - IBActions

private extension AudioPlayer1View {
    @objc func lyricsViewDidTap(_ gestureRecognizer: UITapGestureRecognizer) {
        showLyrics()
    }
}

// MARK: - Progress Setting

private extension AudioPlayer1View {
    func updateLyrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let lyricsInfoList = self.lyricsData?.lyricsInfoList,
                let offSet = NuguCentralManager.shared.client.audioPlayerAgent.offset,
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
            
            if self.lyricsIndex >= lyricsInfoList.count {
                self.lyricsIndex = 0
                return
            }
            
            guard let currentIndexTime = lyricsInfoList[self.lyricsIndex].time,
                let nextIndexTime = self.lyricsIndex+1 >= lyricsInfoList.count ? nil : lyricsInfoList[self.lyricsIndex+1].time else { return }
            
            let offSetInMilliseconds = offSet * 1000
            let currentLyrics = lyricsInfoList[self.lyricsIndex].text
            let nextLyrics = self.lyricsIndex+1 >= lyricsInfoList.count ? "" : lyricsInfoList[self.lyricsIndex+1].text
            
            if currentIndexTime > offSetInMilliseconds {
                self.currentLyricsLabel.textColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1.0)
                self.currentLyricsLabel.text = currentLyrics
                self.nextLyricsLabel.text = nextLyrics
            } else if self.lyricsIndex >= lyricsInfoList.count - 1 {
                self.currentLyricsLabel.text = currentLyrics
                self.nextLyricsLabel.text = nextLyrics
            } else if currentIndexTime <= offSetInMilliseconds && nextIndexTime > offSetInMilliseconds {
                self.currentLyricsLabel.textColor = UIColor(red: 0, green: 157/255.0, blue: 1, alpha: 1.0)
                self.currentLyricsLabel.text = currentLyrics
                self.nextLyricsLabel.text = nextLyrics
                self.fullLyricsView?.updateLyricsFocus(lyricsIndex: self.lyricsIndex)
            } else {
                self.lyricsIndex += 1
                self.updateLyrics()
            }
        }
    }
    
    func setAudioPlayerProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let elapsedTimeAsInt = NuguCentralManager.shared.client.audioPlayerAgent.offset,
                let durationAsInt = NuguCentralManager.shared.client.audioPlayerAgent.duration else {
                    self?.elapsedTimeLabel.text = nil
                    self?.durationTimeLabel.text = nil
                    self?.progressView.isHidden = true
                    return
            }
            self?.progressView.isHidden = false
            let elapsedTime = Float(elapsedTimeAsInt)
            let duration = Float(durationAsInt)
            self?.elapsedTimeLabel.text = Int(elapsedTime).secondTimeString
            self?.durationTimeLabel.text = Int(duration).secondTimeString
            UIView.animate(withDuration: 1.0, animations: { [weak self] in
                let progress = duration == 0 ? 0 : elapsedTime/duration
                self?.progressView.setProgress(progress, animated: true)
            })
        }
    }
    
    func startProgressTimer() {
        audioProgressTimer?.cancel()
        audioProgressTimer = DispatchSource.makeTimerSource(queue: audioProgressTimerQueue)
        audioProgressTimer?.schedule(deadline: .now(), repeating: 1.0)
        audioProgressTimer?.setEventHandler(handler: { [weak self] in
            self?.setAudioPlayerProgress()
        })
        audioProgressTimer?.resume()
        
        lyricsTimer?.cancel()
        lyricsTimer = DispatchSource.makeTimerSource(queue: lyricsTimerQueue)
        lyricsTimer?.schedule(deadline: .now(), repeating: 0.1)
        lyricsTimer?.setEventHandler(handler: { [weak self] in
            self?.updateLyrics()
        })
        lyricsTimer?.resume()
    }
    
    func stopProgressTimer() {
        audioProgressTimer?.cancel()
        audioProgressTimer = nil
        lyricsTimer?.cancel()
        lyricsTimer = nil
    }
}
