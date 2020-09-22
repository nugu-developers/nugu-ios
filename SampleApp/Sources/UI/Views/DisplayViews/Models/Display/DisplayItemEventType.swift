//
//  DisplayItemEventType.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/08/20.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
//

enum DisplayItemEventType {
    case elementSelected(token: String?, postback: [String: AnyHashable]?)
    case textInput(token: String? = nil, textInput: DisplayCommonTemplate.Common.TextInput?)
}
