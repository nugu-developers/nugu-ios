//
//  FocusManager.swift
//  NuguCore
//
//  Created by MinChul Lee on 11/04/2019.
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

import Foundation

public class FocusManager: FocusManageable {
    public weak var delegate: FocusDelegate?
    private var handlingSoundDirectives = Set<String>()
    
    private let focusDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.focus_manager", qos: .userInitiated)
    
    private var channelInfos = [FocusChannelInfo]()
    
    private var releaseFocusWorkItem: DispatchWorkItem?
    
    public init(directiveSequencer: DirectiveSequenceable) {
        directiveSequencer.add(delegate: self)
    }
}

// MARK: - FocusManageable

extension FocusManager {
    public func add(channelDelegate: FocusChannelDelegate) {
        channelInfos.remove(delegate: channelDelegate)
        
        let info = FocusChannelInfo(delegate: channelDelegate, focusState: .nothing)
        channelInfos.append(info)
    }
    
    public func remove(channelDelegate: FocusChannelDelegate) {
        channelInfos.remove(delegate: channelDelegate)
    }
    
    public func requestFocus(channelDelegate: FocusChannelDelegate) {
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.channelInfos.object(forDelegate: channelDelegate) != nil else {
                log.warning("\(channelDelegate): Channel not registered")
                return
            }
            guard self.delegate?.focusShouldAcquire() == true else {
                log.warning("Focus should not acquire. \(channelDelegate.focusChannelPriority())")
                self.update(channelDelegate: channelDelegate, focusState: .nothing)
                return
            }
            
            guard self.foregroundChannelDelegate !== channelDelegate else {
                self.update(channelDelegate: channelDelegate, focusState: .foreground)
                return
            }
            
            // Move current foreground channel to background If Its priority is lower than requested.
            if let foregroundChannelDelegate = self.foregroundChannelDelegate,
                channelDelegate.focusChannelPriority().requestPriority >= foregroundChannelDelegate.focusChannelPriority().maintainPriority {
                self.update(channelDelegate: foregroundChannelDelegate, focusState: .background)
            }

            if let backgroundChannelDelegate = self.backgroundChannelDelegate,
               backgroundChannelDelegate !== channelDelegate,
                channelDelegate.focusChannelPriority().requestPriority < backgroundChannelDelegate.focusChannelPriority().maintainPriority {
                // Assign a higher background channel to the foreground in the future.
                self.update(channelDelegate: channelDelegate, focusState: .background)
            } else if self.foregroundChannelDelegate == nil {
                self.update(channelDelegate: channelDelegate, focusState: .foreground)
            } else {
                self.update(channelDelegate: channelDelegate, focusState: .background)
            }
        }
    }

    public func releaseFocus(channelDelegate: FocusChannelDelegate) {
        focusDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.channelInfos.object(forDelegate: channelDelegate) != nil else {
                log.warning("\(channelDelegate): Channel not registered")
                return
            }
            
            self.update(channelDelegate: channelDelegate, focusState: .nothing)
        }
    }
}

// MARK: - DirectiveSequencerDelegate

extension FocusManager: DirectiveSequencerDelegate {
    public func directiveSequencerWillHandle(directive: Downstream.Directive, blockingPolicy: BlockingPolicy) {
        focusDispatchQueue.async { [weak self] in
            if blockingPolicy.medium == .audio {
                self?.handlingSoundDirectives.insert(directive.header.messageId)
            }
        }
    }
    
    public func directiveSequencerDidHandle(directive: Downstream.Directive, result: DirectiveHandleResult) {
        focusDispatchQueue.async { [weak self] in
            guard let self = self, self.handlingSoundDirectives.isEmpty == false else { return }
            self.handlingSoundDirectives.remove(directive.header.messageId)
            if self.handlingSoundDirectives.isEmpty == true {
                self.notifyReleaseFocusIfNeeded()
            }
        }
    }
}

// MARK: - Private

private extension FocusManager {
    func update(channelDelegate: FocusChannelDelegate, focusState: FocusState) {
        let info = FocusChannelInfo(delegate: channelDelegate, focusState: focusState)
        guard channelInfos.replace(info: info) != nil else {
            log.warning("\(channelDelegate): Failed set to \(focusState).")
            return
        }
        
        channelDelegate.focusChannelDidChange(focusState: focusState)
        
        switch focusState {
        case .nothing:
            assignForeground()
            notifyReleaseFocusIfNeeded()
        case .background, .foreground:
            releaseFocusWorkItem?.cancel()
        }
    }
    
    func assignForeground() {
        // Assign a higher background channel to the foreground with some delay so that it doesn't acquire the focus temporarily.
        focusDispatchQueue.asyncAfter(deadline: .now() + FocusConst.shortLatency) { [weak self] in
            guard let self = self else { return }
            guard self.foregroundChannelDelegate == nil,
                let backgroundChannelDelegate = self.backgroundChannelDelegate else {
                    return
            }
            
            self.update(channelDelegate: backgroundChannelDelegate, focusState: .foreground)
        }
    }
    
    func notifyReleaseFocusIfNeeded() {
        releaseFocusWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard self.handlingSoundDirectives.isEmpty else { return }
            
            if self.channelInfos.allSatisfy({ $0.delegate == nil || $0.focusState == .nothing }) {
                log.debug("")
                self.delegate?.focusShouldRelease()
            }
        }
        releaseFocusWorkItem = workItem
        focusDispatchQueue.asyncAfter(deadline: .now() + FocusConst.releaseLatency, execute: workItem)
    }
    
    var foregroundChannelDelegate: FocusChannelDelegate? {
        return self.channelInfos.first(where: { (info) -> Bool in
            return info.focusState == .foreground
        })?.delegate
    }
    
    var backgroundChannelDelegate: FocusChannelDelegate? {
        return self.channelInfos
            .filter { $0.focusState == .background }
            .compactMap { $0.delegate}
            .sorted { $0.focusChannelPriority().maintainPriority > $1.focusChannelPriority().maintainPriority }
            .first
    }
}
