//
//  NuguToast.swift
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

final public class NuguToast {
    
    // MARK: - NuguToast.Const
    
    private struct ToastConst {
        static let viewOpacity = CGFloat(0.8)
        static let cornerRadius = CGFloat(4)
        static let textVerticalPadding = 24.0
        static let textHorizontalPadding = 14.0
        static let viewMargin = 8.0
        static let bottomMargin = 88.0
        static let animationDuration = 0.3
        static let showingDuration = 7.0
        static let textColor = UIColor.white
        static let textFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        static let backgroundColor = UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    }
    
    // MARK: - Singleton
    
    public static let shared = NuguToast()
    
    // MARK: - Private Properties
    
    private lazy var toastView = UIView()
    private lazy var toastLabel = UILabel()
    
    private var hideAnimationWorkItem: DispatchWorkItem?
    
    private var bottomSafeAreaHeight: CGFloat {
        get {
            guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return 0 }
            if #available(iOS 11.0, *) {
                return rootViewController.view.safeAreaInsets.bottom
            } else {
                return rootViewController.bottomLayoutGuide.length
            }
        }
    }
}

// MARK: - Public

public extension NuguToast {
    func showToast(message: String?, bottomMargin: CGFloat? = nil) {
        guard let window = UIApplication.shared.keyWindow else { return }
        guard let toastMessage = message, toastMessage.count > 0 else { return }
    
        hideAnimationWorkItem?.cancel()
        hideAnimationWorkItem = nil
        
        toastLabel.textAlignment = .center
        toastLabel.textColor = ToastConst.textColor
        toastLabel.font = ToastConst.textFont
        toastLabel.numberOfLines = 0
        toastLabel.preferredMaxLayoutWidth = window.bounds.size.width - CGFloat((ToastConst.viewMargin + ToastConst.textHorizontalPadding) * 2)
        toastLabel.text = toastMessage
        toastLabel.frame = CGRect(origin: CGPoint(x: ToastConst.textHorizontalPadding,
                                                  y: ToastConst.textVerticalPadding),
                                  size: toastLabel.intrinsicContentSize)
        
        toastView.addSubview(toastLabel)
        toastView.backgroundColor = ToastConst.backgroundColor
        toastView.layer.cornerRadius = ToastConst.cornerRadius
        toastView.frame = CGRect(x: 0, y: 0,
                                 width: window.bounds.size.width - CGFloat(ToastConst.viewMargin * 2),
                                 height: toastLabel.intrinsicContentSize.height + CGFloat(ToastConst.textVerticalPadding * 2))
        toastView.center = CGPoint(x: window.center.x,
                                   y: window.bounds.size.height - (toastView.bounds.size.height/2) - (bottomMargin ?? CGFloat(ToastConst.bottomMargin)) - bottomSafeAreaHeight)
        toastLabel.center = CGPoint(x: toastView.frame.size.width/2,
                                    y: toastView.frame.size.height/2)
        toastView.alpha = 0
        
        hideAnimationWorkItem = DispatchWorkItem {
            UIView.animate(
                withDuration: ToastConst.animationDuration,
                animations: { [weak self] in
                    self?.toastView.alpha = 0
                },
                completion: { [weak self] _ in
                    self?.toastLabel.removeFromSuperview()
                    self?.toastView.removeFromSuperview()
            })
        }
        
        UIView.animate(
            withDuration: ToastConst.animationDuration,
            animations: { [weak self] in
                guard let toastView = self?.toastView else { return }
                toastView.alpha = ToastConst.viewOpacity
                window.addSubview(toastView)
                window.bringSubviewToFront(toastView)
            },
            completion: { [weak self] _ in
                if let hideAnimationWorkItem = self?.hideAnimationWorkItem {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ToastConst.showingDuration,
                                                  execute: hideAnimationWorkItem)
                }
        })
    }
    
    func hideToastIfNeeded() {
        if let hideAnimationWorkItem = self.hideAnimationWorkItem {
            hideAnimationWorkItem.cancel()
            self.hideAnimationWorkItem = nil
            UIView.animate(
                withDuration: ToastConst.animationDuration,
                animations: {
                    [weak self] in
                    self?.toastView.alpha = 0
                },
                completion: { [weak self] _ in
                    self?.toastLabel.removeFromSuperview()
                    self?.toastView.removeFromSuperview()
            })
        }
    }
}

