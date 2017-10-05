//
//  OfflineMediaAsset.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-03.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation



//public final class ResumedDownloadTask {
//    fileprivate let assetId: String
//    fileprivate let initError: DownloadError?
//    internal init(assetId: String, error: DownloadError? = nil) {
//        self.assetId = assetId
//        self.initError = error
//    }
//
//    // MARK: DownloadEventPublisher
//    internal var onStarted: (ResumedDownloadTask) -> Void = { _ in }
//    internal var onSuspended: (ResumedDownloadTask) -> Void = { _ in }
//    internal var onResumed: (ResumedDownloadTask) -> Void = { _ in }
//    internal var onCanceled: (ResumedDownloadTask) -> Void = { _ in }
//    internal var onCompleted: (ResumedDownloadTask, URL) -> Void = { _ in }
//    internal var onProgress: (ResumedDownloadTask, Progress) -> Void = { _ in }
//    internal var onError: (ResumedDownloadTask, DownloadError) -> Void = { _ in }
//    internal var onPlaybackReady: (ResumedDownloadTask, URL) -> Void = { _ in }
//    internal var onShouldDownloadMediaOption: ((ResumedDownloadTask, AdditionalMedia) -> MediaOption?) = { _ in return nil }
//    internal var onDownloadingMediaOption: (ResumedDownloadTask, MediaOption) -> Void = { _ in }
//}
//
//extension ResumedDownloadTask {
//    public func isResumable(callback: @escaping (Bool) -> Void) {
//        SessionManager
//            .default
//            .task(assetId: assetId) { task in
//
//                guard let task = task else {
//                    callback(false)
//                    return
//                }
//                switch task.state {
//                case .running: callback(true)
//                case .suspended: callback(true)
//                default: callback(false)
//                }
//        }
//    }
//}
//
//extension ResumedDownloadTask {
//    public func resume() {
//        guard initError == nil else {
//            onError(self, initError!)
//            return
//        }
//    }
//}
//
//extension ResumedDownloadTask: DownloadEventPublisher {
//    public typealias DownloadEventProgress = Progress
//    public typealias DownloadEventError = DownloadError
//
//    @discardableResult
//    public func onStarted(callback: @escaping (ResumedDownloadTask) -> Void) -> ResumedDownloadTask {
//        onStarted = callback
//        return self
//    }
//
//    @discardableResult
//    public func onSuspended(callback: @escaping (ResumedDownloadTask) -> Void) -> ResumedDownloadTask {
//        onSuspended = callback
//        return self
//    }
//
//    @discardableResult
//    public func onResumed(callback: @escaping (ResumedDownloadTask) -> Void) -> ResumedDownloadTask {
//        onResumed = callback
//        return self
//    }
//
//    @discardableResult
//    public func onCanceled(callback: @escaping (ResumedDownloadTask) -> Void) -> ResumedDownloadTask {
//        onCanceled = callback
//        return self
//    }
//
//    @discardableResult
//    public func onCompleted(callback: @escaping (ResumedDownloadTask, URL) -> Void) -> ResumedDownloadTask {
//        onCompleted = callback
//        return self
//    }
//
//    @discardableResult
//    public func onProgress(callback: @escaping (ResumedDownloadTask, Progress) -> Void) -> ResumedDownloadTask {
//        onProgress = callback
//        return self
//    }
//
//    @discardableResult
//    public func onError(callback: @escaping (ResumedDownloadTask, DownloadError) -> Void) -> ResumedDownloadTask {
//        onError = callback
//        return self
//    }
//
//    @discardableResult
//    public func onPlaybackReady(callback: @escaping (ResumedDownloadTask, URL) -> Void) -> ResumedDownloadTask {
//        onPlaybackReady = callback
//        return self
//    }
//
//    @discardableResult
//    public func onShouldDownloadMediaOption(callback: @escaping (ResumedDownloadTask, AdditionalMedia) -> MediaOption?) -> ResumedDownloadTask {
//        onShouldDownloadMediaOption = callback
//        return self
//    }
//
//    @discardableResult
//    public func onDownloadingMediaOption(callback: @escaping (ResumedDownloadTask, MediaOption) -> Void) -> ResumedDownloadTask {
//        onDownloadingMediaOption = callback
//        return self
//    }
//}


public struct OfflineMediaAsset {
//    /// Returns the download task if download is not complete
//    public func downloadTask(callback: @escaping (AVAssetDownloadTask?) -> Void) {
//        SessionManager
//            .default
//            .task(assetId: self.assetId,
//                  callback: callback)
//    }
    
    internal init(assetId: String, url: URL?) {
        self.assetId = assetId
        if let url = url {
            self.urlAsset = AVURLAsset(url: url)
        }
        else {
            self.urlAsset = nil
        }
    }
    
    public let assetId: String
    public let urlAsset: AVURLAsset?
    
//    public func resumeDownload() -> ResumedDownloadTask {
//        guard urlAsset == nil else {
//            return ResumedDownloadTask(assetId: assetId, error: .alreadyDownloaded(assetId: assetId, location: urlAsset!.url))
//        }
//
//        return ResumedDownloadTask(assetId: assetId)
//    }
    
    public func isResumable(callback: @escaping (Bool) -> Void) {
        SessionManager
            .default
            .task(assetId: assetId) { task in
                
                guard let task = task else {
                    callback(false)
                    return
                }
                switch task.state {
                case .running: callback(true)
                case .suspended: callback(true)
                default: callback(false)
                }
        }
    }
    
    public func state(callback: @escaping (State) -> Void) {
        guard let urlAsset = urlAsset else {
            callback(.notPlayable)
            return
        }
        
//        if #available(iOS 10.0, *) {
//            print("PlayableOffline: ",urlAsset.url,urlAsset.assetCache?.isPlayableOffline)
//            if let assetCache = urlAsset.assetCache, assetCache.isPlayableOffline {
//                callback(.completed)
//                return
//            }
//        }
        
        urlAsset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                
                // Check for any issues preparing the loaded values
                var error: NSError?
                if urlAsset.statusOfValue(forKey: "playable", error: &error) == .loaded {
                    if urlAsset.isPlayable {
                        callback(.completed)
                    }
                    else {
                        callback(.notPlayable)
                    }
                }
                else {
                    callback(.notPlayable)
                }
            }
        }
    }
    
    public enum State {
        case completed
        case notPlayable
    }
    
    /// Deletes locally stored asset data
    public func delete() {
        do {
            if let url = urlAsset?.url {
                try FileManager.default.removeItem(at: url)
            }
            
            Downloader.remove(localRecordId: assetId)
            print("👍 Cleaned up local media after user deleted OfflineMediaAsset")
        }
        catch {
            print("🚨 OfflineMediaAsset delete:",error.localizedDescription)
        }
    }
}
