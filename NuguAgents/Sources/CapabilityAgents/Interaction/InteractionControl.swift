//
//  InteractionControl.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/08/07.
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

/**
 interactionControl 필드를 포함하는 directive 에서 사용하는 자료구조
 */
public struct InteractionControl: Codable {
    /**
     multi-turn 이 진행 중인가에 대한 정보
     
     (a)directive->(b)event 에 대한 응답 (c)directive 는 Play 구현에 의존하므로
     (c) 가 내려올 수 있음을 클라이언트에 알려주기 위한 목적
     */
    public let mode: Mode
    
    /**
     전달받은 InteractionControl를 event 통해 전달하기위한 임시 저장소
     */
    public let referrerEvent: ReferrerEvent?
    
    public enum Mode: String, Codable {
        case none = "NONE"
        case multiTurn = "MULTI_TURN"
    }
    
    public struct ReferrerEvent: Codable {
        /**
         Event로 return해야 하는 agent의 type
         */
        public let type: String
    }
}
