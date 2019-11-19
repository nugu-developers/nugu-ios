//
//  NuguVoiceChromeAnimationView.swift
//  NuguUIKit
//
//  Created by jin kim on 2019/11/14.
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

final class NuguVoiceChromeAnimationView: UIView {
    
    private let standardAnimationViewSize = CGSize(width: 128.0, height: 64.0)
    private let blueColor = UIColor(red: 0, green: 158.0/255.0, blue: 1, alpha: 1.0).cgColor
    private let greenColor = UIColor(red: 0, green: 230.0/255.0, blue: 136.0/255.0, alpha: 1.0).cgColor
    private let redColor = UIColor(red: 1, green: 58.0/255.0, blue: 0, alpha: 1.0).cgColor
    private let whiteColor = UIColor.white.cgColor

    func setAnimation(state: NuguVoiceChrome.State) {
        layer.sublayers = nil
        let centerPoint = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        let frameRatio = min(frame.size.width / standardAnimationViewSize.width, frame.size.height / standardAnimationViewSize.height)
        switch state {
        case .listeningPassive:
            listeningPassiveAnimation(centerPoint: centerPoint, frameRatio: frameRatio)
        case .listeningActive:
            listeningActiveAnimation(centerPoint: centerPoint, frameRatio: frameRatio)
        case .processing:
            processingAnimation(centerPoint: centerPoint, frameRatio: frameRatio)
        case .speaking:
            speakingAnimationWithColor(centerPoint: centerPoint, frameRatio: frameRatio, shapeLayerColor: blueColor)
        case .speakingError:
            speakingAnimationWithColor(centerPoint: centerPoint, frameRatio: frameRatio, shapeLayerColor: redColor)
        }
    }
}

private extension NuguVoiceChromeAnimationView {
    func listeningPassiveAnimation(centerPoint: CGPoint, frameRatio: CGFloat) {
        let listeningPassiveAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        listeningPassiveAnimation.timingFunctions = [CAMediaTimingFunction(name: .linear)]
        listeningPassiveAnimation.values = [0, 2 * frameRatio, -2 * frameRatio, 0]
        listeningPassiveAnimation.duration = 1.6
        listeningPassiveAnimation.repeatCount = .infinity
        for index in 0 ..< 4 {
            let circleRadius: CGFloat = 4.0 * frameRatio
            let circleSize = CGSize(width: circleRadius * 2, height: circleRadius * 2)
            let shapeLayer = CAShapeLayer()
            let circlePath = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: circleSize),
                cornerRadius: circleRadius
            )
            shapeLayer.fillColor = (index % 2 == 0) ? greenColor : blueColor
            shapeLayer.path = circlePath.cgPath
            let space = circleRadius * 3
            shapeLayer.frame = CGRect(
                origin: CGPoint(
                    x: centerPoint.x - (4 * circleRadius + 1.5 * space) + (CGFloat(index) * (2 * circleRadius + space)),
                    y: centerPoint.y - circleRadius
                ),
                size: circleSize
            )
            listeningPassiveAnimation.beginTime = CACurrentMediaTime() + (Double(index) * 0.2)
            shapeLayer.add(listeningPassiveAnimation, forKey: "listeningPassiveAnimation")
            layer.addSublayer(shapeLayer)
        }
    }
    
    func listeningActiveAnimation(centerPoint: CGPoint, frameRatio: CGFloat) {
        let circleRadius: CGFloat = 4.0 * frameRatio
        let circleSize = CGSize(width: circleRadius * 2, height: circleRadius * 2)
        for index in 0 ..< 4 {
            let circlePath = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: circleSize),
                cornerRadius: circleRadius
            )
            
            var expandedHeight: CGFloat = 0
            var compressedHeight: CGFloat = 0
            switch index % 4 {
            case 0, 2:
                expandedHeight = 20 * frameRatio
                compressedHeight = 16 * frameRatio
            case 1:
                expandedHeight = 44 * frameRatio
                compressedHeight = 34 * frameRatio
            case 3:
                expandedHeight = 24 * frameRatio
                compressedHeight = 20 * frameRatio
            default:
                break
            }
            
            let expandedPath = UIBezierPath(
                roundedRect: CGRect(x: 0, y: -(expandedHeight/2) + 4, width: circleSize.width, height: expandedHeight),
                cornerRadius: circleRadius
            )
            
            let compressedPath = UIBezierPath(
                roundedRect: CGRect(x: 0, y: -(compressedHeight/2) + 4, width: circleSize.width, height: compressedHeight),
                cornerRadius: circleRadius
            )
            
            let expandAnimation = CABasicAnimation(keyPath: "path")
            expandAnimation.fromValue = circlePath.cgPath
            expandAnimation.toValue = expandedPath.cgPath
            expandAnimation.duration = 0.1
            
            let springAnimation = CABasicAnimation(keyPath: "path")
            springAnimation.fromValue = expandedPath.cgPath
            springAnimation.toValue = compressedPath.cgPath
            springAnimation.beginTime = 0.1
            springAnimation.repeatCount = .infinity
            springAnimation.duration = 0.1
            springAnimation.autoreverses = true
            
            let backToCircleAnimation = CABasicAnimation(keyPath: "path")
            backToCircleAnimation.fromValue = compressedPath.cgPath
            backToCircleAnimation.toValue = circlePath.cgPath
            backToCircleAnimation.beginTime = 0.6
            backToCircleAnimation.duration = 0.1
            
            let animations = CAAnimationGroup()
            animations.beginTime = CACurrentMediaTime()
            animations.duration = 0.7
            animations.repeatCount = .infinity
            animations.autoreverses = true
            animations.animations = [expandAnimation, springAnimation, backToCircleAnimation]
            
            let shapeLayer: CAShapeLayer = CAShapeLayer()
            shapeLayer.fillColor = (index % 2 == 0) ? greenColor : blueColor
            let space = circleRadius * 3
            shapeLayer.frame = CGRect(
                origin: CGPoint(
                    x: centerPoint.x - (4 * circleRadius + 1.5 * space) + (CGFloat(index) * (2 * circleRadius + space)),
                    y: centerPoint.y - circleRadius),
                size: circleSize)
            shapeLayer.add(animations, forKey: "listeningActiveAnimation")
            shapeLayer.transform = CATransform3DMakeRotation(30.0 * CGFloat.pi / 180.0, 0, 0, 1.0)
            layer.addSublayer(shapeLayer)
        }
    }
    
    func processingAnimation(centerPoint: CGPoint, frameRatio: CGFloat) {
        let jumpAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        jumpAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeIn)]
        jumpAnimation.values = [12.5 * frameRatio, -12.5 * frameRatio]
        jumpAnimation.duration = 0.2
        jumpAnimation.repeatCount = .infinity
        jumpAnimation.autoreverses = true
        
        let verticalStretchAnimation = CAKeyframeAnimation(keyPath: "transform.scale.y")
        verticalStretchAnimation.timingFunctions = [CAMediaTimingFunction(name: .linear)]
        verticalStretchAnimation.keyTimes = [0, 0.66, 1]
        verticalStretchAnimation.values = [0.9, 1.1, 1.0]
        verticalStretchAnimation.duration = 0.2
        verticalStretchAnimation.repeatCount = .infinity
        verticalStretchAnimation.autoreverses = true
        
        let horizontalStretchAnimation = CAKeyframeAnimation(keyPath: "transform.scale.x")
        horizontalStretchAnimation.timingFunctions = [CAMediaTimingFunction(name: .linear)]
        horizontalStretchAnimation.keyTimes = [0, 1]
        horizontalStretchAnimation.values = [1.1, 0.9]
        horizontalStretchAnimation.duration = 0.2
        horizontalStretchAnimation.repeatCount = .infinity
        horizontalStretchAnimation.autoreverses = true

        let shapeLayer: CAShapeLayer = CAShapeLayer()
        let circleRadius: CGFloat = 6.0 * frameRatio
        let circleSize = CGSize(width: circleRadius * 2, height: circleRadius * 2)
        let circlePath = UIBezierPath(
            roundedRect: CGRect(origin: .zero, size: circleSize),
            cornerRadius: circleRadius
        )
        shapeLayer.fillColor = blueColor
        shapeLayer.path = circlePath.cgPath
        shapeLayer.frame = CGRect(origin: CGPoint(x: centerPoint.x - circleRadius, y: centerPoint.y - circleRadius), size: circleSize)
        shapeLayer.add(verticalStretchAnimation, forKey: "verticalStretchAnimation")
        shapeLayer.add(horizontalStretchAnimation, forKey: "horizontalStretchAnimation")
        shapeLayer.add(jumpAnimation, forKey: "jumpAnimation")
        layer.addSublayer(shapeLayer)
    }
    
    func speakingAnimationWithColor(centerPoint: CGPoint, frameRatio: CGFloat, shapeLayerColor: CGColor) {
        let circleRadius: CGFloat = 4.5 * frameRatio
        let circleSize = CGSize(width: circleRadius * 2, height: circleRadius * 2)
        let expandedWidth: CGFloat = 65.0 * frameRatio
        let expandedSize = CGSize(width: expandedWidth, height: circleRadius * 2)
        
        let circlePath = UIBezierPath(
            roundedRect: CGRect(origin: CGPoint(x: expandedWidth/2 - circleRadius, y: 0), size: circleSize),
            cornerRadius: circleRadius
        )
        
        let expandedPath = UIBezierPath(
            roundedRect: CGRect(origin: .zero, size: expandedSize),
            cornerRadius: circleRadius
        )
        
        let expandAnimation = CABasicAnimation(keyPath: "path")
        expandAnimation.fromValue = circlePath.cgPath
        expandAnimation.toValue = expandedPath.cgPath
        expandAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        expandAnimation.duration = 0.4
        expandAnimation.repeatCount = .infinity
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.keyTimes = [0, 1]
        opacityAnimation.values = [0.75, 0.25]
        opacityAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeInEaseOut)]
        opacityAnimation.duration = 0.4
        opacityAnimation.repeatCount = .infinity
        
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        shapeLayer.fillColor = shapeLayerColor
        shapeLayer.path = expandedPath.cgPath
        shapeLayer.frame = CGRect(origin: CGPoint(x: centerPoint.x - expandedWidth/2, y: centerPoint.y - circleRadius), size: circleSize)
        layer.addSublayer(shapeLayer)
        
        let animationLayer: CAShapeLayer = CAShapeLayer()
        animationLayer.fillColor = whiteColor
        animationLayer.frame = shapeLayer.frame
        animationLayer.add(expandAnimation, forKey: "expandAnimation")
        animationLayer.add(opacityAnimation, forKey: "opacityAnimation")
        layer.addSublayer(animationLayer)
    }
}
