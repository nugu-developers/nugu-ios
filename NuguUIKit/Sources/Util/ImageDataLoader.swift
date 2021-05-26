//
//  ImageDataLoader.swift
//  NuguUIKit
//
//  Created by yonghoonKwon on 20/07/2019.
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

final public class ImageDataLoader {
    public static let shared = ImageDataLoader()
    
    @discardableResult
    public func load(
        imageUrl: URL,
        completionQueue: DispatchQueue = DispatchQueue.main,
        completion: @escaping ((Result<Data, Error>) -> Void)
        ) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: imageUrl) { (data, _, error) in
            let result: Result<Data, Error>
            defer {
                completionQueue.async {
                    completion(result)
                }
            }
            
            if let error = error {
                result = .failure(error)
                return
            }
            
            guard let imageData = data else {
                result = .failure(NSError())
                return
            }
            
            result = .success(imageData)
        }
        
        task.resume()
        return task
    }
}

// MARK: - UIImageView + ImageDataLoader

extension UIImageView {
    @discardableResult
    func loadImage(from urlString: String?, failureImage: UIImage? = nil) -> URLSessionDataTask? {
        guard
            let imageUrlString = urlString,
            let url = URL(string: imageUrlString)
            else {
                log.debug("Failed load image, url is nil or invalid \(urlString ?? "")")
                self.image = failureImage
                return nil
        }
        
        return ImageDataLoader.shared.load(imageUrl: url) { (result) in
            switch result {
            case .success(let imageData):
                self.image = UIImage(data: imageData)
            case .failure(let error):
                self.image = failureImage
                log.debug("Failed load image: \(error)")
            }
        }
    }
}

// MARK: - UIButton + ImageDataLoader

extension UIButton {
    @discardableResult
    func loadImage(from urlString: String?) -> URLSessionDataTask? {
        guard
            let imageUrlString = urlString,
            let url = URL(string: imageUrlString)
            else {
                log.debug("Failed load image, url is nil or invalid \(urlString ?? "")")
                self.setImage(nil, for: .normal)
                return nil
        }
        
        return ImageDataLoader.shared.load(imageUrl: url) { (result) in
            switch result {
            case .success(let imageData):
                self.setImage(UIImage(data: imageData), for: .normal)
            case .failure(let error):
                self.setImage(nil, for: .normal)
                log.debug("Failed load image: \(error)")
            }
        }
    }
}
