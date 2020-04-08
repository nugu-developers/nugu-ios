//
//  MediaCacheManager.swift
//  NuguCore
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/04/06.
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
import AVFoundation

class MediaCacheManager {
    private static let aesKey = "_AISMediaAesKey_"
    
    // TODO: - Should change to configurable value
    private static let isCacheEnabled = true
    
    private static let cacheFolderPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("MediaCache", isDirectory: true)
    private static let cacheSizeLimit = 1024 * 1024 * 500
    
    private static let supportedMimeTypeForCaching = ["audio/mp4", "audio/aac"]
}

// MARK: - Internal Methods

extension MediaCacheManager {
    class func checkCacheAvailablity(itemURL: URL, cacheKey: String, completion: @escaping ((_ isAvailable: Bool, _ cacheExists: Bool, _ endUrl: URL) -> (Void))) {
        guard isCacheEnabled else {
            completion(false, false, itemURL)
            return
        }
        
        var request: URLRequest = URLRequest(url: itemURL)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { (_, response, _) in
            guard let httpURLResponse = response as? HTTPURLResponse,
                let contentType = httpURLResponse.allHeaderFields["Content-Type"] as? String else {
                    completion(false, false, itemURL)
                    return
            }

            log.debug("+++ \(httpURLResponse) +++")
            
            completion(
                supportedMimeTypeForCaching.contains(contentType),
                doesCacheFileExist(key: cacheKey),
                httpURLResponse.url ?? itemURL // Redirect 가 일어나는 Asset 의 경우 간헐적으로 재생이 실패하는 이슈가 있다. EndURL 을 새로 세팅해준다.
            )
        }.resume()
    }
    
    class func getCachedPlayerItem(cacheKey: String) -> MediaAVPlayerItem? {
        guard let localFileData = NSData(contentsOfFile: MediaCacheManager.getCacheFilePathUrl(key: cacheKey).path),
            let decryptedData = MediaCacheManager.decryptData(data: localFileData)
            else {
                _ = MediaCacheManager.removeTempFile(key: cacheKey)
                return nil
        }
        
        do {
            try decryptedData.write(to: MediaCacheManager.getTempFilePathUrl(key: cacheKey))
            return MediaAVPlayerItem(url: MediaCacheManager.getTempFilePathUrl(key: cacheKey))
        } catch {
            _ = MediaCacheManager.removeTempFile(key: cacheKey)
            return nil
        }
    }
    
    class func saveMediaData(mediaData: NSData, cacheKey: String) -> Bool {
        guard let encryptedData = encryptData(data: mediaData) as NSData? else {
            return false
        }
        
        log.debug("Total Cache folder size Will Reach to : \(getTotalCachedData() + encryptedData.length)")
        while (getTotalCachedData() + encryptedData.length) > cacheSizeLimit {
            if encryptedData.length > cacheSizeLimit {
                break
            }
            
            // 삭제에 실패한 경우 캐쉬데이터를 생성하지 않는다.
            if removeLeastRecentlyUsedCacheFile() == false {
                return false
            }
        }
        
        do {
            try encryptedData.write(to: pathForCacheFolder().appendingPathComponent("\(cacheKey).securedata"), options: .atomic)
            log.debug("Total Cache After Save : \(getTotalCachedData())")
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Path Related Methods (private)

private extension MediaCacheManager {
    class func pathForCacheFolder() -> URL {
        var isDir: ObjCBool = false
        let pathForCacheFolder = URL(fileURLWithPath: cacheFolderPath.path, isDirectory: true)
        
        if FileManager.default.fileExists(atPath: pathForCacheFolder.path, isDirectory: &isDir) == true {
            if isDir.boolValue {
                return pathForCacheFolder
            } else {
                do {
                    try FileManager.default.createDirectory(atPath: pathForCacheFolder.path, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    
                }
            }
        } else {
            do {
                try FileManager.default.createDirectory(atPath: pathForCacheFolder.path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                
            }
        }
        return pathForCacheFolder
    }

    class func getCacheFilePathUrl(key: String) -> URL {
        return pathForCacheFolder().appendingPathComponent("\(key).securedata")
    }
    
    class func getTempFilePathUrl(key: String) -> URL {
        return pathForCacheFolder().appendingPathComponent("\(key)_temp.mp3")
    }
}
    
// MARK: - Existence Check Methods (private)

private extension MediaCacheManager {
    class func doesCacheFileExist(key: String) -> Bool {
        return FileManager.default.fileExists(atPath: pathForCacheFolder().appendingPathComponent("\(key).securedata").path)
    }
    
    class func doesTempFileExist(key: String) -> Bool {
        return FileManager.default.fileExists(atPath: pathForCacheFolder().appendingPathComponent("\(key)_temp.mp3").path)
    }
}

// MARK: - Remove Cache Methods (private)

private extension MediaCacheManager {
    class func removeCacheFile(key: String) -> Bool {
        do {
            try FileManager.default.removeItem(at: getCacheFilePathUrl(key: key))
            return true
        } catch {
            return false
        }
    }
    
    class func removeTempFile(key: String) -> Bool {
        do {
            try FileManager.default.removeItem(at: getTempFilePathUrl(key: key))
            return true
        } catch {
            return false
        }
    }
    
    class func removeLeastRecentlyUsedCacheFile() -> Bool {
        do {
            var oldestCachedFileKey: String?
            var oldestModifiedDate = Date()

            let contentList = try FileManager.default.contentsOfDirectory(atPath: pathForCacheFolder().path).filter {
                // 생성한 securedata 캐쉬파일만 캐쉬관리로직에 의한 삭제를 시도한다.
                // 캐쉬폴더 경로와 캐쉬사이즈를 app.단에서 조절할 수 있도록 api를 생성하였는데, 이렇게 하면 모든 캐쉬해야할 파일을 한 폴더에 모을수도 있기 때문.
                $0.hasSuffix(".securedata")
            }
            let contentFileKeyList = contentList.map {
                $0.replacingOccurrences(of: ".securedata", with: "")
            }
            
            for cachedFileKey in contentFileKeyList {
                let cachedFileAttribute = try FileManager.default.attributesOfItem(atPath: getCacheFilePathUrl(key: cachedFileKey).path)
                if let lastModifiedDate = cachedFileAttribute[FileAttributeKey.modificationDate] as? Date {
                    if lastModifiedDate < oldestModifiedDate {
                        oldestModifiedDate = lastModifiedDate
                        oldestCachedFileKey = cachedFileKey
                    }
                }
            }
            guard let removableCachedFileKey = oldestCachedFileKey else { return false }
            
            log.debug("oldestDate = \(oldestModifiedDate), oldestKey = \(removableCachedFileKey)")
            return removeCacheFile(key: removableCachedFileKey)
        } catch {
            log.error("removeNotRecentlyUsedCacheFile Exception!!!")
            return false
        }
    }
}

// MARK: - Utilty Methods (private)

private extension MediaCacheManager {
    class func getTotalCachedData() -> Int {
        return FileManager.default.folderSizeAtPath(path: pathForCacheFolder().path)
    }
    
    class func setModifiedDateForCacheFile(key: String) {
        do {
            try FileManager.default.setAttributes([FileAttributeKey.modificationDate: Date()], ofItemAtPath: getCacheFilePathUrl(key: key).path)
        } catch {
            log.error("FAIL TO SET ATTRIBUTE")
        }
    }
    
    class func clearMediaCache() {
        do {
            for file in try FileManager.default.contentsOfDirectory(atPath: pathForCacheFolder().path) {
                let filePath = pathForCacheFolder().appendingPathComponent(file).path
                try FileManager.default.removeItem(atPath: filePath)
            }
        } catch {
            
        }
    }
}

// MARK: - AESEncrypt & AESDecrypt Methods (private)

private extension MediaCacheManager {
    class func encryptData(data: NSData) -> Data? {
        return CryptoUtil.encrypt(data: data as Data, key: aesKey)
    }
    
    class func decryptData(data: NSData) -> Data? {
        return CryptoUtil.decrypt(data: data as Data, key: aesKey)
    }
}
