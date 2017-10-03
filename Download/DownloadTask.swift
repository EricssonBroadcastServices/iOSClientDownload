//
//  DownloadTask.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public final class DownloadTask {
    public struct Progress {
//        /// Size in bytes
//        public let size: Int64
//        
//        /// Total size in bytes
//        public let total: Int64
        
        /// Current progress measured in [0,1]
        public let current: Double
    }
    
    internal struct Configuration {
        let url: URL
        let name: String
        let artwork: Data?
        
        /// location.bookmarkData()
        /// Bookmark data should be used when persisting this url to disk
        ///
        /// - important: destination URL will be handled diffrently on iOS 9 vs iOS 10. On the later version, storage url for local media is handled and assigned by the system. In iOS 9 this path is supplied by the user.
        var destination: URL?
    }
    
    
    ///  During the initial asset download, the user’s default media selections—their primary audio and video tracks—are downloaded. If additional media selections such as subtitles, closed captions, or alternative audio tracks are found, the session delegate’s URLSession:assetDownloadTask:didResolveMediaSelection: method is called, indicating that additional media selections exist on the server. To download additional media selections, save a reference to this resolved AVMediaSelection object so you can create subsequent download tasks to be executed serially.
    internal var resolvedMediaSelection: AVMediaSelection?
    
    internal let urlAsset: AVURLAsset
    internal var configuration: Configuration
    fileprivate var fairplayRequester: DownloadFairplayRequester?
    
    internal lazy var delegate: DownloadTaskDelegate = { [unowned self] in
        return DownloadTaskDelegate(task: self)
        }()
    
    fileprivate var task: AVAssetDownloadTask?
    fileprivate let sessionManager: SessionManager
    
    /// New, fresh DownloadTasks
    internal init(sessionManager: SessionManager, configuration: Configuration, fairplayRequester: DownloadFairplayRequester? = nil) {
        self.sessionManager = sessionManager
        self.configuration = configuration
        self.fairplayRequester = fairplayRequester
        
        urlAsset = AVURLAsset(url: configuration.url)
        
        if fairplayRequester != nil {
            urlAsset.resourceLoader.setDelegate(fairplayRequester, queue: DispatchQueue(label: configuration.name + "-offlineFairplayLoader"))
        }
    }
    
//    /// Resumed from suspended session
//    init(task: AVAssetDownloadTask, sessionManager: SessionManager, configuration: Configuration, fairplayRequester: DownloadFairplayRequester? = nil) {
//        self.task = task
//
//        self.sessionManager = sessionManager
//        self.configuration = configuration
//        self.fairplayRequester = fairplayRequester
//
//        urlAsset = task.urlAsset
//
//        if fairplayRequester != nil {
//            urlAsset.resourceLoader.setDelegate(fairplayRequester, queue: DispatchQueue(label: configuration.name + "-offlineFairplayLoader"))
//        }
//    }
    
    // MARK: FairPlay
    public func fairplay(requester: DownloadFairplayRequester) -> DownloadTask {
        fairplayRequester = requester
        urlAsset.resourceLoader.setDelegate(requester, queue: DispatchQueue(label: configuration.name + "-offlineFairplayLoader"))
        return self
    }
    
    // Controls
    public func resume() {
        // AVAssetDownloadTask provides the ability to resume previously stopped downloads under certain circumstances. To do so, simply instantiate a new AVAssetDownloadTask with an AVURLAsset instantiated with a file NSURL pointing to the partially downloaded bundle with the desired download options, and the download will continue restoring any previously downloaded data. FPS keys remain encrypted in persisted form during this process.
        guard let task = task else {
            let options = requiredBitrate != nil ? [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: requiredBitrate!] : nil
            
            startTask(with: options) { error in
                guard error == nil else {
                    onError(self, error!)
                    return
                }
                onStarted(self)
            }
            return
        }
        task.resume()
        onResumed(self)
    }
    
    /// NOTE: Can/will replacing the previous task cause problems? Investigate
    internal func startTask(with options: [String: Any]?, callback: (DownloadError?) -> Void) {
        if #available(iOS 10.0, *) {
            DispatchQueue(label: "com.emp.download.startTask." + UUID().uuidString).sync {
                
                guard let task = sessionManager
                    .session
                    .makeAssetDownloadTask(asset: urlAsset,
                                           assetTitle: configuration.name,
                                           assetArtworkData: configuration.artwork,
                                           options: options) else {
                                            // This method may return nil if the AVAssetDownloadURLSession has been invalidated.
                                            callback(.downloadSessionInvalidated)
                                            return
                }
                self.task = task
                task.taskDescription = configuration.name
                
                sessionManager.delegate[task] = self
                
                task.resume()
                callback(nil)
            }
        }
        else {
            guard let destination = configuration.destination else {
                onError(self, .storageUrlNotFound)
                return
            }
            
            guard let task = sessionManager
                .session
                .makeAssetDownloadTask(asset: urlAsset,
                                       destinationURL: destination,
                                       options: options) else {
                                        // This method may return nil if the URLSession has been invalidated
                                        callback(.downloadSessionInvalidated)
                                        return
            }
            
            self.task = task
            task.taskDescription = configuration.name
            
            sessionManager.delegate[task] = self
            
            task.resume()
            callback(nil)
        }
    }
    
    
    public func suspend() {
        // If a download has been started, it can be stopped. AVAssetDownloadTask inherits from NSURLSessionTask, and downloads can be suspended or cancelled using the corresponding methods inherited from NSURLSessionTask. In the case where a download is stopped and there is no intention of resuming it, apps are responsible for deleting the portion of the asset already downloaded to a user’s device. The NSURLSessionTask documentation on developer.apple.com contains more details about this process.
        
        guard let task = self.task else { return }
        task.suspend()
        onSuspended(self)
    }
    
    public func cancel() {
        // Downloaded HLS assets can be deleted using [NSFileManager removeItemAtURL:] with the URL for the downloaded version of the asset. In addition, if a user deletes the app that downloaded the HLS assets, they will also delete all content that the app stored to disk.
        
        guard let task = self.task else { return }
        task.cancel()
        
        // NOTE: `onCanceled` called once `didCompleteWithError` delegate methods is triggered
    }
    
    // Configuration
    fileprivate var requiredBitrate: Int64?
    
    /// The lowest media bitrate greater than or equal to this value will be selected. If no suitable media bitrate is found, the highest media bitrate will be selected. If this option is not specified, the highest media bitrate will be selected for download by default.
    ///
    /// - parameter bitrate: The bitrate to select, in bps (bits per second)
    @discardableResult
    public func use(bitrate: Int64?) -> Self {
        requiredBitrate = bitrate
        return self
    }
    
    public enum State {
        case notStarted
        case running
        case suspended
        case canceling
        case completed
    }
    
    public var state: State {
        guard let state = task?.state else { return .notStarted}
        switch state {
        case .running: return .running
        case .suspended: return .suspended
        case .canceling: return .canceling
        case .completed: return .completed
        }
    }
    
    // State
    //    public var currentProgress: Progress {
    //        ?????
    //    }
    
    // MARK: DownloadEventPublisher
    internal var onStarted: (DownloadTask) -> Void = { _ in }
    internal var onSuspended: (DownloadTask) -> Void = { _ in }
    internal var onResumed: (DownloadTask) -> Void = { _ in }
    internal var onCanceled: (DownloadTask) -> Void = { _ in }
    internal var onCompleted: (DownloadTask, URL) -> Void = { _ in }
    internal var onProgress: (DownloadTask, Progress) -> Void = { _ in }
    internal var onError: (DownloadTask, DownloadError) -> Void = { _ in }
    internal var onPlaybackReady: (DownloadTask, URL) -> Void = { _ in }
    internal var onShouldDownloadMediaOption: ((DownloadTask, AdditionalMedia) -> MediaOption?) = { _ in return nil }
    internal var onDownloadingMediaOption: (DownloadTask, MediaOption) -> Void = { _ in }
}

extension DownloadTask {
    /// Returns currently downloaded subtitles
    @available(iOS 10.0, *)
    public var localSubtitles: [MediaOption] {
        return urlAsset.localSubtitles
    }
    
    /// Returns currently downloaded subtitles
    @available(iOS 10.0, *)
    public var localAudio: [MediaOption] {
        return urlAsset.localAudio
    }
    
    /// Returns currently downloaded subtitles
    @available(iOS 10.0, *)
    public var localVideo: [MediaOption] {
        return urlAsset.localVideo
    }
}

extension DownloadTask: DownloadEventPublisher {
    public typealias DownloadEventProgress = Progress
    public typealias DownloadEventError = DownloadError
    
    @discardableResult
    public func onStarted(callback: @escaping (DownloadTask) -> Void) -> DownloadTask {
        onStarted = callback
        return self
    }
    
    @discardableResult
    public func onSuspended(callback: @escaping (DownloadTask) -> Void) -> DownloadTask {
        onSuspended = callback
        return self
    }
    
    @discardableResult
    public func onResumed(callback: @escaping (DownloadTask) -> Void) -> DownloadTask {
        onResumed = callback
        return self
    }
    
    @discardableResult
    public func onCanceled(callback: @escaping (DownloadTask) -> Void) -> DownloadTask {
        onCanceled = callback
        return self
    }
    
    @discardableResult
    public func onCompleted(callback: @escaping (DownloadTask, URL) -> Void) -> DownloadTask {
        onCompleted = callback
        return self
    }
    
    @discardableResult
    public func onProgress(callback: @escaping (DownloadTask, Progress) -> Void) -> DownloadTask {
        onProgress = callback
        return self
    }
    
    @discardableResult
    public func onError(callback: @escaping (DownloadTask, DownloadError) -> Void) -> DownloadTask {
        onError = callback
        return self
    }
    
    @discardableResult
    public func onPlaybackReady(callback: @escaping (DownloadTask, URL) -> Void) -> DownloadTask {
        onPlaybackReady = callback
        return self
    }
    
    @discardableResult
    public func onShouldDownloadMediaOption(callback: @escaping (DownloadTask, AdditionalMedia) -> MediaOption?) -> DownloadTask {
        onShouldDownloadMediaOption = callback
        return self
    }
    
    @discardableResult
    public func onDownloadingMediaOption(callback: @escaping (DownloadTask, MediaOption) -> Void) -> DownloadTask {
        onDownloadingMediaOption = callback
        return self
    }
}
