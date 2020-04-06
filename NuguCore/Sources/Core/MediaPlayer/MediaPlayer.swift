//
//  MediaPlayer.swift
//  NuguCore
//
//  Created by MinChul Lee on 22/04/2019.
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
import AVFoundation
import MobileCoreServices

public class MediaPlayer: NSObject, MediaPlayable {
    public weak var delegate: MediaPlayerDelegate?
    
    private var player: AVQueuePlayer?
    private var playerItem: MediaAVPlayerItem?
    
    private var downloadSession: URLSession?
    private var downloadDataTask: URLSessionDataTask?
    private var downloadResponse: URLResponse?
    private var downloadAudioData: NSData?
    
    private var expectedDataLength: Float?
    private var sessionHasFinishedLoading: Bool?
    private var pendingRequests = Set<AVAssetResourceLoadingRequest>()
    private var pendingRequestQueue = DispatchQueue(label: "com.sktelecom.romain.pendingRequest")
}

// MARK: - MediaPlayable

extension MediaPlayer {
    public func play() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                self.delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.notPrepareSource))
                return
        }
        
        mediaPlayer.play()
        
        delegate?.mediaPlayerDidChange(state: .start)
    }
    
    public func stop() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                self.delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.notPrepareSource))
                return
        }
        
        mediaPlayer.replaceCurrentItem(with: nil)
        playerItem?.delegate = nil  // CHECK-ME: 타이밍 이슈 없을지 확인
        
        playerItem = nil
        player = nil
        
        delegate?.mediaPlayerDidChange(state: .stop)
    }
    
    public func pause() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                self.delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.notPrepareSource))
                return
        }
        
        mediaPlayer.pause()
        
        delegate?.mediaPlayerDidChange(state: .pause)
    }
    
    public func resume() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                self.delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.notPrepareSource))
                return
        }
        
        mediaPlayer.play()
        
        delegate?.mediaPlayerDidChange(state: .resume)
    }
    
    public func seek(to offset: TimeIntervallic, completion: ((Result<Void, Error>) -> Void)?) {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                completion?(.failure(MediaPlayableError.notPrepareSource))
                return
        }

        mediaPlayer.seek(to: offset.cmTime)
        completion?(.success(()))
    }
    
    public var offset: TimeIntervallic {
        guard let mediaPlayer = player else {
            log.warning("player is nil")
            return NuguTimeInterval(seconds: 0)
        }
        
        return mediaPlayer.currentTime()
    }
    
    public var duration: TimeIntervallic {
        guard let asset = player?.currentItem?.asset else {
            log.warning("player is nil")
            return NuguTimeInterval(seconds: 0)
        }
        
        return asset.duration
    }
    
    public var volume: Float {
        get {
            return player?.volume ?? 1.0
        }
        set {
            player?.volume = newValue
        }
    }
}

// MARK: - MediaPlayer + MediaUrlDataSource

extension MediaPlayer: MediaUrlDataSource {
    public func setSource(url: String, offset: TimeIntervallic, cacheKey: String?) throws {
        guard let urlItem = URL(string: url) else {
            throw MediaPlayableError.invalidURL
        }
        
        playerItem = MediaAVPlayerItem(url: urlItem)
        
        guard let playerItem = playerItem else {
            throw MediaPlayableError.unknown
        }
        
        playerItem.cacheKey = cacheKey
        
        // 음악 재생시엔 캐시 정책에 맞게 플레이해주어야 한다..
        if let itemKeyForCache = playerItem.cacheKey,
            MediaCacheManager.isPlayerItemAvailableForCache(playerItem: playerItem) {
            // 캐쉬가 존재하면 로컬로 재생한다.
            if MediaCacheManager.doesCacheFileExist(key: itemKeyForCache) == true {
                self.playerItem = self.getLocalFilePlayerItem(playerItemToConfigure: playerItem)
            }
            // 캐쉬가 존재하지 않으면 다운로드를 위한 AVAssetResourceLoader 델리게이트를 연결시켜준다.
            else {
                self.playerItem = self.getDownloadAndPlayPlayerItem(playerItemToConfigure: playerItem)
            }
        }
        
        self.playerItem?.delegate = self
        player = AVQueuePlayer(playerItem: self.playerItem)
                
        if offset.seconds > 0 {
            player?.seek(to: offset.cmTime)
        }
    }
}

// MARK: - Cache setting

extension MediaPlayer {
    func getLocalFilePlayerItem(playerItemToConfigure: MediaAVPlayerItem) -> MediaAVPlayerItem? {
        guard let itemKeyForCache = playerItemToConfigure.cacheKey,
            let localFileData = NSData(contentsOfFile: MediaCacheManager.getCacheFilePathUrl(key: itemKeyForCache).path),
            let decryptedData = MediaCacheManager.decryptData(data: localFileData)
            
            else {
                if let keyForRemove = playerItemToConfigure.cacheKey {
                    _ = MediaCacheManager.removeTempFile(key: keyForRemove)
                }
                return getDownloadAndPlayPlayerItem(playerItemToConfigure: playerItemToConfigure)
        }
        
        do {
            try decryptedData.write(to: MediaCacheManager.getTempFilePathUrl(key: itemKeyForCache))
            return MediaAVPlayerItem(url: MediaCacheManager.getTempFilePathUrl(key: itemKeyForCache))
        } catch {
            _ = MediaCacheManager.removeTempFile(key: itemKeyForCache)
            return getDownloadAndPlayPlayerItem(playerItemToConfigure: playerItemToConfigure)
        }
    }
    
    func getDownloadAndPlayPlayerItem(playerItemToConfigure: MediaAVPlayerItem) -> MediaAVPlayerItem? {
        guard let originalUrl = (playerItemToConfigure.asset as? AVURLAsset)?.url else { return nil }
        guard var urlComponents = URLComponents(url: originalUrl, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.scheme = "streaming"
      
        guard let urlModel = urlComponents.url else { return nil }
        let urlAsset = AVURLAsset(url: urlModel)
        urlAsset.resourceLoader.setDelegate(self, queue: DispatchQueue.global())

        return MediaAVPlayerItem(asset: urlAsset)
    }
}

// MARK: AVAssetResourceLoader Delegate Methods

extension MediaPlayer: AVAssetResourceLoaderDelegate {
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        _ = pendingRequestQueue.sync {
            pendingRequests.insert(loadingRequest)
        }
        
        if sessionHasFinishedLoading == true {
            processPendingRequests()
        }
        
        if downloadSession == nil {
            sessionHasFinishedLoading = false
            var urlToConvert = URLComponents(url: loadingRequest.request.url!, resolvingAgainstBaseURL: false)
            urlToConvert!.scheme = "http"
            let interceptedURL = urlToConvert!.url!
            startDataRequest(withURL: interceptedURL)
        }
        
        return true
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        _ = pendingRequestQueue.sync {
            pendingRequests.remove(loadingRequest)
        }
    }
}

// MARK: Audio Download Methods

private extension MediaPlayer {
    func startDataRequest(withURL url: URL) {
        log.debug("startDataRequest - URL : \(url.absoluteString)")
        let request = URLRequest(url: url)
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let downloadSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let urlSessionDatatask = downloadSession.dataTask(with: request)
        urlSessionDatatask.resume()
    }
    
    func processPendingRequests() {
        var requestsCompleted = Set<AVAssetResourceLoadingRequest>()
        for loadingRequest in pendingRequests {
            fillInContentInformation(contentInformationRequest: loadingRequest.contentInformationRequest)
            let didRespondCompletely = respondWithDataForRequest(dataRequest: loadingRequest.dataRequest!)
            if didRespondCompletely {
                requestsCompleted.insert(loadingRequest)
                loadingRequest.finishLoading()
            }
        }
        
        pendingRequestQueue.sync {
            pendingRequests.subtract(requestsCompleted)
        }
    }
    
    func fillInContentInformation(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
        guard let downloadResponse = downloadResponse,
            let mimeType = downloadResponse.mimeType else { return }
        
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
        guard let contentType = unmanagedFileUTI?.takeRetainedValue() else {
            return
        }
        
        log.debug("origianal mimeType = \(mimeType) // translated mimeType = \(contentType as String)")
        
        contentInformationRequest?.contentType = contentType as String
        contentInformationRequest?.contentLength = downloadResponse.expectedContentLength
        contentInformationRequest?.isByteRangeAccessSupported = true
    }
    
    func respondWithDataForRequest(dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        var startOffset = dataRequest.requestedOffset
        if dataRequest.currentOffset != 0 {
            startOffset = dataRequest.currentOffset
        }
        
        // Don't have any data at all for this request
        guard let downloadAudioData = downloadAudioData else {
            return false
        }
        
        if downloadAudioData.length < Int(startOffset) {
            return false
        }
        
        // This is the total data we have from startOffset to whatever has been downloaded so far
        let unreadBytes = downloadAudioData.length - Int(startOffset)
        
        // Respond with whatever is available if we can't satisfy the request fully yet
        let numberOfBytesToRespondWith = min(Int(dataRequest.requestedLength), unreadBytes)
        let range = NSRange(location: Int(startOffset), length: numberOfBytesToRespondWith)
        
        dataRequest.respond(with: (downloadAudioData.subdata(with: range)))
        
        let endOffset = Int(startOffset) + dataRequest.requestedLength
        let didRespondFully = downloadAudioData.length >= endOffset
        return didRespondFully
    }
    
    private func releaseCacheData() {
        downloadDataTask?.cancel()
        downloadDataTask = nil
        downloadSession = nil
        downloadAudioData = nil
        downloadResponse = nil

        if pendingRequests.count > 0 {
            for request in pendingRequests {
                request.finishLoading()
            }
        }
        
        pendingRequestQueue.sync {
            pendingRequests.removeAll()
        }
    }
}

// MARK: URLSessionData Delegate
extension MediaPlayer: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(URLSession.ResponseDisposition.allow)
        downloadAudioData = NSMutableData()
        downloadResponse = response
        processPendingRequests()
        expectedDataLength = Float(response.expectedContentLength)
    }
    
    // 간헐적 Crash 이슈로 Delegate 메소드 optional 처리. 참고 > https://github.com/Alamofire/Alamofire/issues/2138
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        internalUrlSession(session: session, dataTask: dataTask, didReceive: data)
    }
    
    private func internalUrlSession(session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data?) {
        guard let data = data else {
            return
        }
        
        guard let downloadAudioData = downloadAudioData as? NSMutableData else {
            processPendingRequests()
            return
        }
        
        downloadAudioData.append(data)
        log.debug("\(Float(downloadAudioData.length) / Float(expectedDataLength!))")
        processPendingRequests()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        sessionHasFinishedLoading = true
        
        if error != nil {
            log.error("\(error!)")
            releaseCacheData()
            return
        }
        
        processPendingRequests()
        
        guard var audioDataToWrite = downloadAudioData,
            let itemKeyForCache = playerItem?.cacheKey,
            let encryptedData = MediaCacheManager.encryptData(data: audioDataToWrite)else {
            releaseCacheData()
            return
        }
        
        audioDataToWrite = encryptedData as NSData
        
        if MediaCacheManager.saveDataToCacheFile(data: audioDataToWrite, key: itemKeyForCache) == true {
            log.debug("SaveComplete: \(itemKeyForCache)")
        } else {
            log.error("SaveFailed")
        }
        releaseCacheData()
    }
}

// MARK: - MediaAVPlayerItemDelegate

extension MediaPlayer: MediaAVPlayerItemDelegate {
    func mediaAVPlayerItem(_ playerItem: MediaAVPlayerItem,
                           didChangePlaybackStatus status: MediaAVPlayerItem.PlaybackStatus) {
        switch status {
        case .failed(let error):
            guard let playerItemError = error else {
                delegate?.mediaPlayerDidChange(state: .error(error: MediaPlayableError.unknown))
                break
            }
            
            delegate?.mediaPlayerDidChange(state: .error(error: playerItemError))
        default:
            break
        }
    }
    
    func mediaAVPlayerItem(_ playerItem: MediaAVPlayerItem,
                           didChangeBufferState status: MediaAVPlayerItem.BufferState) {
        delegate?.mediaPlayerDidChange(state: status.mediaPlayerState)
    }
    
    func mediaAVPlayerItemPlaybackStalled(_ playerItem: MediaAVPlayerItem) {
        //
    }
    
    func mediaAVPlayerItemDidPlayToEndTime(_ playerItem: MediaAVPlayerItem) {
        delegate?.mediaPlayerDidChange(state: .finish)
    }
}

// MARK: - MediaAVPlayerItem.BufferState + MediaPlayerState

private extension MediaAVPlayerItem.BufferState {
    var mediaPlayerState: MediaPlayerState {
        switch self {
        case .bufferFinished: return .bufferRefilled
        case .buffering: return .bufferUnderrun
        }
    }
}
