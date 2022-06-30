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

/// <#Description#>
final public class NuguToast {
    
    // MARK: - NuguToast.Duration
    
    public enum Duration: Int {
        case short = 4
        case long = 7
    }
    
    // MARK: - NuguToast.Const
    
    private struct ToastConst {
        static let viewOpacity = CGFloat(0.8)
        static let cornerRadius = CGFloat(4)
        static let textVerticalPadding = 24.0
        static let textHorizontalPadding = 14.0
        static let viewMargin = 8.0
        static let bottomMargin = 88.0
        static let animationDuration = 0.3
        static let textColor = UIColor.white
        static let textFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        static let backgroundColor = UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    }
    
    // MARK: - Singleton
    
    /// <#Description#>
    public static let shared = NuguToast()
    
    // MARK: - Private Properties
    
    private lazy var toastView = UIView()
    private lazy var toastLabel = UILabel()
    
    private var hideAnimationWorkItem: DispatchWorkItem?
}

// MARK: - Public

public extension NuguToast {
    /// <#Description#>
    /// - Parameters:
    ///   - message: <#message description#>
    ///   - bottomMargin: <#bottomMargin description#>
    func showToast(message: String?, bottomMargin: CGFloat? = nil, duration: Duration = .short) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first else { return }
            guard let toastMessage = message, toastMessage.count > 0 else { return }
            
            self.hideAnimationWorkItem?.cancel()
            self.hideAnimationWorkItem = nil
            
            self.toastLabel.textAlignment = .center
            self.toastLabel.textColor = ToastConst.textColor
            self.toastLabel.font = ToastConst.textFont
            self.toastLabel.numberOfLines = 0
            self.toastLabel.preferredMaxLayoutWidth = window.bounds.size.width - CGFloat((ToastConst.viewMargin + ToastConst.textHorizontalPadding) * 2)
            self.toastLabel.text = toastMessage
            self.toastLabel.frame = CGRect(origin: CGPoint(x: ToastConst.textHorizontalPadding,
                                                      y: ToastConst.textVerticalPadding),
                                           size: self.toastLabel.intrinsicContentSize)
            
            self.toastView.addSubview(self.toastLabel)
            self.toastView.backgroundColor = ToastConst.backgroundColor
            self.toastView.layer.cornerRadius = ToastConst.cornerRadius
            self.toastView.frame = CGRect(x: 0, y: 0,
                                     width: window.bounds.size.width - CGFloat(ToastConst.viewMargin * 2),
                                     height: self.toastLabel.intrinsicContentSize.height + CGFloat(ToastConst.textVerticalPadding * 2))
            self.toastView.center = CGPoint(x: window.center.x,
                                            y: window.bounds.size.height - (self.toastView.bounds.size.height/2) - (bottomMargin ?? CGFloat(ToastConst.bottomMargin)) - SafeAreaUtil.bottomSafeAreaHeight)
            self.toastLabel.center = CGPoint(x: self.toastView.frame.size.width/2,
                                             y: self.toastView.frame.size.height/2)
            self.toastView.alpha = 0
            
            self.hideAnimationWorkItem = DispatchWorkItem {
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
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(duration.rawValue),
                                                      execute: hideAnimationWorkItem)
                    }
                })
        }
    }
    
    /// <#Description#>
    func hideToastIfNeeded() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let hideAnimationWorkItem = self.hideAnimationWorkItem {
                hideAnimationWorkItem.cancel()
                self.hideAnimationWorkItem = nil
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
        }
    }
}
