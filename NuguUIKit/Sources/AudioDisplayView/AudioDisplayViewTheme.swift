//
//  AudioDisplayViewTheme.swift
//  NuguUIKit
//
//  Created by 김진님/AI Assistant개발 Cell on 2021/05/28.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
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

public enum AudioDisplayTheme {
    case light
    case dark
    
    var backgroundColor: UIColor {
        switch self {
        case .light:
            return UIColor(red: 248.0/255.0, green: 248.0/255.0, blue: 248.0/255.0, alpha: 1.0)
        case .dark:
            return .black
        }
    }
    
    var barPlayerBackgroundColor: UIColor {
        switch self {
        case .light:
            return .white
        case .dark:
            return .black
        }
    }
    
    var titleViewTextColor: UIColor {
        switch self {
        case .light:
            return UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
        case .dark:
            return .white
        }
    }
    
    var titleLabelTextColor: UIColor {
        switch self {
        case .light:
            return .black
        case .dark:
            return .white
        }
    }
    
    var subTitleLabelTextColor: UIColor {
        switch self {
        case .light:
            return UIColor(red: 68.0/255.0, green: 68.0/255.0, blue: 68.0/255.0, alpha: 1.0)
        case .dark:
            return .white
        }
    }
    
    var fullLyricsHeaderLabelTextColor: UIColor {
        switch self {
        case .light:
            return UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
        case .dark:
            return .white
        }
    }
    
    var fullLyricsLabelTextColor: UIColor {
        switch self {
        case .light:
            return UIColor(red: 68.0/255.0, green: 68.0/255.0, blue: 68.0/255.0, alpha: 1.0)
        case .dark:
            return UIColor(red: 136.0/255.0, green: 136.0/255.0, blue: 136.0/255.0, alpha: 1.0)
        }
    }
    
    var progressViewTrackTintColor: UIColor {
        switch self {
        case .light:
            return UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 0.2)
        case .dark:
            return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.1)
        }
    }
    
    var barProgressViewTrackTintColor: UIColor {
        switch self {
        case .light:
            return UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 0.2)
        case .dark:
            return UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
        }
    }
    
    var playImage: UIImage? {
        switch self {
        case .light:
            return UIImage(named: "btn_play", in: Bundle.imageBundle, compatibleWith: nil)
        case .dark:
            return UIImage(named: "btn_play_dark", in: Bundle.imageBundle, compatibleWith: nil)
        }
    }
    
    var pauseImage: UIImage? {
        switch self {
        case .light:
            return UIImage(named: "btn_pause", in: Bundle.imageBundle, compatibleWith: nil)
        case .dark:
            return UIImage(named: "btn_pause_dark", in: Bundle.imageBundle, compatibleWith: nil)
        }
    }
    
    var prevImage: UIImage? {
        switch self {
        case .light:
            return UIImage(named: "btn_skip_previous", in: Bundle.imageBundle, compatibleWith: nil)
        case .dark:
            return UIImage(named: "btn_skip_previous_dark", in: Bundle.imageBundle, compatibleWith: nil)
        }
    }
    
    var nextImage: UIImage? {
        switch self {
        case .light:
            return UIImage(named: "btn_skip_next", in: Bundle.imageBundle, compatibleWith: nil)
        case .dark:
            return UIImage(named: "btn_skip_next_dark", in: Bundle.imageBundle, compatibleWith: nil)
        }
    }
}
