//
//  EndedUp.swift
//  NuguUtils
//
//  Created by childc on 2020/11/17.
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

import Foundation

public enum EndedUp<Failure: Error>  {
    case success
    case failure(Failure)
    
    @inlinable
    public func mapError<NewFailure>(_ transform: (Failure) -> NewFailure) -> EndedUp<NewFailure> {
        switch self {
        case .success:
            return .success
        case let .failure(failure):
            return .failure(transform(failure))
        }
    }
    
    @inlinable
    public func flatMapError<NewFailure>(_ transform: (Failure) -> EndedUp<NewFailure>) -> EndedUp<NewFailure> {
        switch self {
        case .success:
            return .success
        case let .failure(failure):
            return transform(failure)
        }
    }
}

extension EndedUp: Equatable where Failure: Equatable {}
extension EndedUp: Hashable where Failure: Hashable {}

public extension EndedUp where Failure: Error {
    func toResult() -> Result<Void, Failure> {
        switch self {
        case let .failure(error):
            return .failure(error)
        default:
            return .success(())
        }
    }
}

public extension Result where Success == Void, Failure: Error {
    func toEndedUp() -> EndedUp<Failure> {
        switch self {
        case let .failure(error):
            return .failure(error)
        default:
            return .success
        }
    }
}
