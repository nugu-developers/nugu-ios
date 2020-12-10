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

import NuguUtils

public class MediaPlayer: NSObject, MediaPlayable {
    public weak var delegate: MediaPlayerDelegate?
    
    private var player: AVQueuePlayer?
    private var playerItem: MediaAVPlayerItem?
    
    private var downloadSession: URLSession?
    private var downloadDataTask: URLSessionDataTask?
    private var downloadResponse: URLResponse?
    private var downloadAudioData: Data?
    
    private let schemeForInterception = "streaming"
    private var originalScheme: String?
    
    private var expectedDataLength: Float?
    private var sessionHasFinishedLoading: Bool?
    private var pendingRequests = Set<AVAssetResourceLoadingRequest>()
    private var pendingRequestQueue = DispatchQueue(label: "com.sktelecom.romain.pendingRequest")
}

// MARK: - MediaPlayable

extension MediaPlayer {
    public func play() {
        guard let mediaPlayer = player,
              mediaPlayer.currentItem != nil else {
            delegate?.mediaPlayerStateDidChange(.error(error: MediaPlayableError.notPrepareSource), mediaPlayer: self)
            return
        }
        mediaPlayer.play()
        delegate?.mediaPlayerStateDidChange(.start, mediaPlayer: self)
    }
    
    public func stop() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
            delegate?.mediaPlayerStateDidChange(.error(error: MediaPlayableError.notPrepareSource), mediaPlayer: self)
            return
        }
        
        mediaPlayer.replaceCurrentItem(with: nil)
        playerItem?.delegate = nil  // CHECK-ME: 타이밍 이슈 없을지 확인
        
        playerItem = nil
        player = nil
        
        delegate?.mediaPlayerStateDidChange(.stop, mediaPlayer: self)
    }
    
    public func pause() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
            delegate?.mediaPlayerStateDidChange(.error(error: MediaPlayableError.notPrepareSource), mediaPlayer: self)
            return
        }
        
        mediaPlayer.pause()
        
        delegate?.mediaPlayerStateDidChange(.pause, mediaPlayer: self)
    }
    
    public func resume() {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
            delegate?.mediaPlayerStateDidChange(.error(error: MediaPlayableError.notPrepareSource), mediaPlayer: self)
            return
        }
        
        mediaPlayer.play()
        
        delegate?.mediaPlayerStateDidChange(.resume, mediaPlayer: self)
    }
    
    public func seek(to offset: TimeIntervallic, completion: ((EndedUp<Error>) -> Void)?) {
        guard
            let mediaPlayer = player,
            mediaPlayer.currentItem != nil else {
                completion?(.failure(MediaPlayableError.notPrepareSource))
                return
        }

        mediaPlayer.seek(to: offset.cmTime)
        completion?(.success)
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
        guard asset.statusOfValue(forKey: "duration", error: nil) == .loaded else {
            asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
                guard let self = self else { return }
                guard let asset = self.player?.currentItem?.asset else {
                    log.warning("player is nil")
                    return
                }
                
                let status = asset.statusOfValue(forKey: "duration", error: nil)
                switch status {
                case .loaded:
                    self.delegate?.mediaPlayerDurationDidChange(asset.duration, mediaPlayer: self)
                default:
                    break
                }
            }
            log.debug("Duration not loaded")
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
    public func setSource(url: String, offset: TimeIntervallic, cacheKey: String?) {
        guard let urlItem = URL(string: url) else {
            delegate?.mediaPlayerStateDidChange(.error(error: MediaPlayableError.invalidURL), mediaPlayer: self)
            return
        }
        
        setSource(url: urlItem, offset: offset, cacheKey: cacheKey)
    }
    
    public func setSource(url: URL, offset: TimeIntervallic, cacheKey: String?) {
        if let cacheKey = cacheKey {
            let cacheResult = MediaCacheManager.checkCacheAvailablity(itemURL: url, cacheKey: cacheKey)
            if cacheResult.isAvailable {
                playerItem = cacheResult.cacheExists ? getCachedPlayerItem(cacheKey: cacheKey, itemURL: cacheResult.endUrl) : getDownloadAndPlayPlayerItem(cacheKey: cacheKey, itemURL: cacheResult.endUrl)
            } else {
                let asset = AVAsset(url: url)
                playerItem = MediaAVPlayerItem(asset: asset, cacheKey: cacheKey)
            }
        } else {
            playerItem = MediaAVPlayerItem(url: url)
        }
        
        playerItem?.cacheKey = cacheKey
        playerItem?.delegate = self
        player = AVQueuePlayer(playerItem: playerItem)
        
        if offset.seconds > 0 {
            player?.seek(to: offset.cmTime)
        }
    }
}

// MARK: - Load MediaAVPlayerItem

extension MediaPlayer {
    func getCachedPlayerItem(cacheKey: String, itemURL: URL) -> MediaAVPlayerItem {
        guard let cachedPlayerItem = MediaCacheManager.getCachedPlayerItem(cacheKey: cacheKey) else {
            return getDownloadAndPlayPlayerItem(cacheKey: cacheKey, itemURL: itemURL)
        }
        return cachedPlayerItem
    }
    
    func getDownloadAndPlayPlayerItem(cacheKey: String, itemURL: URL) -> MediaAVPlayerItem {
        guard var urlComponents = URLComponents(url: itemURL, resolvingAgainstBaseURL: false) else {
            return MediaAVPlayerItem(asset: AVAsset(url: itemURL), cacheKey: cacheKey)
        }
        originalScheme = urlComponents.scheme
        urlComponents.scheme = schemeForInterception
        guard let urlModel = urlComponents.url else {
            return MediaAVPlayerItem(asset: AVAsset(url: itemURL), cacheKey: cacheKey)
        }
        let urlAsset = AVURLAsset(url: urlModel)
        urlAsset.resourceLoader.setDelegate(self, queue: DispatchQueue.global())
        
        return MediaAVPlayerItem(asset: urlAsset, cacheKey: cacheKey)
    }
}

// MARK: - AVAssetResourceLoader Delegate Methods

extension MediaPlayer: AVAssetResourceLoaderDelegate {
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let originalScheme = originalScheme else {
            log.error("originalScheme should not be nil")
            return false
        }
        
        pendingRequestQueue.sync {
            _ = pendingRequests.insert(loadingRequest)
        }
        
        if sessionHasFinishedLoading == true {
            processPendingRequests()
        }
        
        if downloadSession == nil {
            guard let url = loadingRequest.request.url,
            var urlToConvert = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                log.error("intercepted url is invalid")
                return false
            }
            
            sessionHasFinishedLoading = false
            urlToConvert.scheme = originalScheme
            
            guard let convertedUrl = urlToConvert.url else {
                log.error("intercepted url is invalid")
                return false
            }
            
            startDataRequest(withURL: convertedUrl)
        }
        
        return true
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequestQueue.sync {
            _ = pendingRequests.remove(loadingRequest)
        }
    }
}

// MARK: Audio Download Methods

private extension MediaPlayer {
    func startDataRequest(withURL url: URL) {
        let request = URLRequest(url: url)
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        downloadSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        downloadDataTask = downloadSession?.dataTask(with: request)
        downloadDataTask?.resume()
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
        
        if downloadAudioData.count < Int(startOffset) {
            return false
        }
        
        // This is the total data we have from startOffset to whatever has been downloaded so far
        let unreadBytes = downloadAudioData.count - Int(startOffset)
        
        // Respond with whatever is available if we can't satisfy the request fully yet
        let numberOfBytesToRespondWith = min(Int(dataRequest.requestedLength), unreadBytes)
        let range = Int(startOffset) ..< Int(startOffset) + numberOfBytesToRespondWith
        
        dataRequest.respond(with: downloadAudioData.subdata(in: range))
        
        let endOffset = Int(startOffset) + dataRequest.requestedLength
        let didRespondFully = downloadAudioData.count >= endOffset
        return didRespondFully
    }
    
    private func releaseCacheData() {
        downloadDataTask?.cancel()
        downloadDataTask = nil
        downloadSession = nil
        downloadAudioData = nil
        downloadResponse = nil
        originalScheme = nil

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

// MARK: - URLSessionData Delegate

extension MediaPlayer: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(URLSession.ResponseDisposition.allow)
        downloadAudioData = Data()
        downloadResponse = response
        processPendingRequests()
        expectedDataLength = Float(response.expectedContentLength)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        internalUrlSession(session: session, dataTask: dataTask, didReceive: data)
    }
    
    // Crash issue resolved by optional Data > https://github.com/Alamofire/Alamofire/issues/2138
    private func internalUrlSession(session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data?) {
        guard let data = data else {
            return
        }
        
        guard downloadAudioData != nil else {
            processPendingRequests()
            return
        }
        
        self.downloadAudioData?.append(data)
        
        if let downloadAudioData = downloadAudioData,
            let expectedDataLength = expectedDataLength {
            log.debug("\(Float(downloadAudioData.count) / Float(expectedDataLength))")
        } else {
            log.debug("expectedDataLength should not be nil!")
        }
        
        processPendingRequests()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            releaseCacheData()
        }
        
        sessionHasFinishedLoading = true
        
        if error != nil {
            log.error("\(error!)")
            return
        }
        
        processPendingRequests()
        
        guard let audioDataToWrite = downloadAudioData,
            let itemKeyForCache = playerItem?.cacheKey else {
            return
        }
        
        MediaCacheManager.saveMediaData(
            mediaData: audioDataToWrite,
            cacheKey: itemKeyForCache
            ) ? log.debug("SaveComplete: \(itemKeyForCache)") : log.error("SaveFailed")
    }
}

// MARK: - MediaAVPlayerItemDelegate

extension MediaPlayer: MediaAVPlayerItemDelegate {
    func mediaAVPlayerItem(_ playerItem: MediaAVPlayerItem,
                           didChangePlaybackStatus status: MediaAVPlayerItem.PlaybackStatus) {
        switch status {
        case .failed(let error):
            guard let playerItemError = error else {
                delegate?.mediaPlayerStateDidChange(.error(error: MediaPlayableError.unknown), mediaPlayer: self)
                break
            }
            
            delegate?.mediaPlayerStateDidChange(.error(error: playerItemError), mediaPlayer: self)
        case .readyToPlay:
            if let cacheKey = playerItem.cacheKey {
                MediaCacheManager.setModifiedDateForCacheFile(key: cacheKey)
            }
        default:
            break
        }
    }
    
    func mediaAVPlayerItem(_ playerItem: MediaAVPlayerItem,
                           didChangeBufferState status: MediaAVPlayerItem.BufferState) {
        delegate?.mediaPlayerStateDidChange(status.mediaPlayerState, mediaPlayer: self)
    }
    
    func mediaAVPlayerItemPlaybackStalled(_ playerItem: MediaAVPlayerItem) {}
    
    func mediaAVPlayerItemDidPlayToEndTime(_ playerItem: MediaAVPlayerItem) {
        delegate?.mediaPlayerStateDidChange(.finish, mediaPlayer: self)
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
