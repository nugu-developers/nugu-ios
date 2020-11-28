//
//  AudioPlayerBarView.swift
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

final class AudioPlayerBarView: UIView {
    @IBOutlet weak var imageVIew: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    private var audioProgressTimer: DispatchSourceTimer?
    private let audioProgressTimerQueue = DispatchQueue(label: "com.sktelecom.romaine.AudioPlayerBarView.audioProgress")
    
    weak var delegate: AudioPlayerBarViewDelegate?
    
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
        let view = Bundle(for: AudioPlayerBarView.self).loadNibNamed("AudioPlayerBarView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = CGRect(origin: view.frame.origin, size: CGSize(width: UIScreen.main.bounds.size.width, height: view.frame.size.height))
        addSubview(view)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap(gestureRecognizer:)))
        addGestureRecognizer(tapRecognizer)
    }
    
    func setData(imageUrl: String?, headerText: String?, bodyText: String?) {
        imageVIew.loadImage(from: imageUrl)
        headerLabel.text = headerText
        bodyLabel.text = bodyText
        startProgressTimer()
    }
    
    @objc func viewDidTap(gestureRecognizer: UITapGestureRecognizer) {
        delegate?.onViewTap()
    }
    
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        delegate?.onCloseButtonClick()
    }
    
    @IBAction func previousButtonDidClick(_ button: UIButton) {
        delegate?.onPreviousButtonClick()
    }
    
    @IBAction func playPauseDidClick(_ button: UIButton) {
        if button.isSelected {
            delegate?.onPauseButtonClick()
        } else {
            delegate?.onPlayButtonClick()
        }
    }
    
    @IBAction func nextButtonDidClick(_ button: UIButton) {
        delegate?.onNextButtonClick()
    }
}

// MARK: - Progress Setting

private extension AudioPlayerBarView {
    func setAudioPlayerProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let elapsedTimeAsInt = self?.delegate?.requestOffset(),
                  let durationAsInt = self?.delegate?.requestDuration() else {
                    self?.progressView.isHidden = true
                    return
            }
            let elapsedTime = Float(elapsedTimeAsInt)
            let duration = Float(durationAsInt)
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
    }
    
    func stopProgressTimer() {
        audioProgressTimer?.cancel()
        audioProgressTimer = nil
    }
}
