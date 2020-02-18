//
//  ImageDataLoader.swift
//  SampleApp
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

final class ImageDataLoader {
    static let shared = ImageDataLoader()
    private init() {
        // Singleton
    }
    
    @discardableResult
    func load(
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
                result = .failure(SampleAppError.nilValue(description: "Image data is nil"))
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
    func loadImage(from urlString: String?) -> URLSessionDataTask? {
        guard
            let imageUrlString = urlString,
            let url = URL(string: imageUrlString)
            else {
                log.debug("Failed load image, url is nil or invalid \(urlString ?? "")")
                self.image = nil
                return nil
        }
        
        return ImageDataLoader.shared.load(imageUrl: url) { (result) in
            switch result {
            case .success(let imageData):
                self.image = UIImage(data: imageData)
            case .failure(let error):
                self.image = nil
                log.debug("Failed load image: \(error)")
            }
        }
    }
}
