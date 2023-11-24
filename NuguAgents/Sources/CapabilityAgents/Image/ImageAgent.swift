//
//  ImageAgent.swift
//  NuguAgents
//
//  Created by jayceSub on 2023/05/10.
//  Copyright (c) 2023 SK Telecom Co., Ltd. All rights reserved.
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

import Foundation
import UIKit

import NuguCore

import RxSwift

private enum Const {
    static let imageSizeThreshHold: CGFloat = 640
    static let resizedImageQuality: CGFloat = 0.9
    static let originalImageQuality: CGFloat = 1
}

public class ImageAgent: ImageAgentProtocol {
    public var capabilityAgentProperty: CapabilityAgentProperty = .init(category: .image, version: "1.1")
    
    // private
    private let directiveSequencer: DirectiveSequenceable
    private let contextManager: ContextManageable
    private let upstreamDataSender: UpstreamDataSendable
    
    // Handleable Directive
    private var handleableDirectiveInfos: [DirectiveHandleInfo] = []
    
    private let imageQueue = DispatchQueue(label: "com.sktelecom.romaine.image_agent")
    private let disposeBag = DisposeBag()
    
    public init(
        directiveSequencer: DirectiveSequenceable,
        contextManager: ContextManageable,
        upstreamDataSender: UpstreamDataSendable
    ) {
        self.directiveSequencer = directiveSequencer
        self.contextManager = contextManager
        self.upstreamDataSender = upstreamDataSender
        
        contextManager.addProvider(contextInfoProvider)
        directiveSequencer.add(directiveHandleInfos: handleableDirectiveInfos.asDictionary)
    }
    
    deinit {
        contextManager.removeProvider(contextInfoProvider)
    }
    
    public lazy var contextInfoProvider: ContextInfoProviderType = { [weak self] completion in
        guard let self = self else { return }
        
        let payload: [String: AnyHashable] = ["version": self.capabilityAgentProperty.version]
        completion(ContextInfo(contextType: .capability, name: self.capabilityAgentProperty.name, payload: payload))
    }
}

// MARK: - Events

public extension ImageAgent {
    @discardableResult func requestSendImage(
        _ image: Data,
        service: [String: AnyHashable]?,
        playServiceId: String?,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> String {
        let eventIdentifier = EventIdentifier()
        
        imageQueue.async { [weak self] in
            guard let imageData = self?.resizeToSuitableResolution(imageData: image) else {
                log.error("Image resize failed")
                return
            }
            
            self?.contextManager.getContexts { [weak self] contextPayload in
                guard let self = self else { return }
                self.upstreamDataSender.sendStream(
                    Event(
                        typeInfo: .sendImage(service: service, playServiceId: playServiceId),
                        referrerDialogRequestId: nil
                    ).makeEventMessage(
                        property: self.capabilityAgentProperty,
                        eventIdentifier: eventIdentifier,
                        contextPayload: contextPayload
                    ),
                    completion: nil
                )
                
                self.upstreamDataSender.sendStream(
                    Attachment(typeInfo: .sendImage)
                        .makeAttachmentImage(
                            property: self.capabilityAgentProperty,
                            eventIdentifier: eventIdentifier,
                            attachmentSeq: 0,
                            isEnd: true,
                            imageData: imageData
                        ),
                    completion: completion
                )
            }
        }
        
        return eventIdentifier.dialogRequestId
    }
    
    private func resizeToSuitableResolution(imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        // width, height중 640보다 큰 것을 640에 맞춘다
        var ratio: CGFloat {
            switch (image.size.width, image.size.height) {
            case let (width, height) where Const.imageSizeThreshHold < width && Const.imageSizeThreshHold < height:
                // 둘 다 크다면 그중 작은 것을 640으로 맞춘다
                let smallerSide = min(width, height)
                return Const.imageSizeThreshHold / smallerSide
                
            case let (width, _) where Const.imageSizeThreshHold < width:
                return Const.imageSizeThreshHold / width
                
            case let (_, height) where Const.imageSizeThreshHold < height:
                return Const.imageSizeThreshHold / height
                
            default:
                return 1
            }
        }
        
        if ratio < 1 {
            let targetSize: CGSize = .init(width: image.size.width * ratio, height: image.size.height * ratio)
            log.debug("Resize to: \(targetSize), original size: \(image.size)")
            return image.resize(to: targetSize)?.jpegData(compressionQuality: Const.resizedImageQuality)
        }
        
        return image.jpegData(compressionQuality: Const.originalImageQuality)
    }
}

// MARK: - Private(Event)

private extension ImageAgent {
    @discardableResult func sendCompactContextEvent(
        _ event: Single<Eventable>,
        completion: ((StreamDataState) -> Void)? = nil
    ) -> EventIdentifier {
        let eventIdentifier = EventIdentifier()
        upstreamDataSender.sendEvent(
            event,
            eventIdentifier: eventIdentifier,
            context: self.contextManager.rxContexts(namespace: self.capabilityAgentProperty.name),
            property: capabilityAgentProperty,
            completion: completion
        ).subscribe().disposed(by: disposeBag)
        return eventIdentifier
    }
}
