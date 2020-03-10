//
//  MockStreamDataRouter.swift
//  NuguTests
//
//  Created by yonghoonKwon on 2020/02/11.
//  Copyright (c) 2020 SK Telecom Co., Ltd. All rights reserved.
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

import NuguCore

class MockStreamDataRouter: StreamDataRoutable {
    var delegate: DownstreamDataDelegate?
    
    var chargingFreeUrl: String = ""
    
    func startReceiveServerInitiatedDirective(resultHandler: ((Result<Downstream.Directive, Error>) -> Void)?) {

    }
    
    func stopReceiveServerInitiatedDirective() {

    }
    
    func handOffResourceServer(to serverPolicy: Policy.ServerPolicy) {

    }
    
    func sendEvent(upstreamEventMessage: UpstreamEventMessage, completion: ((Result<Void, Error>) -> Void)?, resultHandler: ((Result<Downstream.Directive, Error>) -> Void)?) {

    }
    
    func send(crashReports: [CrashReport]) {

    }
    
    func sendStream(upstreamAttachment: UpstreamAttachment, completion: ((Result<Void, Error>) -> Void)?) {

    }
    
    func sendStream(upstreamEventMessage: UpstreamEventMessage, completion: ((Result<Void, Error>) -> Void)?, resultHandler: ((Result<Downstream.Directive, Error>) -> Void)?) {

    }
    
    
}
