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
        /// Current progress measured in [0,1]
        public let current: Double
    }
    
    internal struct Configuration {
        let url: URL
        let assetId: String
        let artwork: Data?
        
        /// location.bookmarkData()
        /// Bookmark data should be used when persisting this url to disk
        ///
        /// - important: destination URL will be handled diffrently on iOS 9 vs iOS 10. On the later version, storage url for local media is handled and assigned by the system. In iOS 9 this path is supplied by the user.
        var destination: URL?
    }
    
    
    ///  During the initial asset download, the user’s default media selections—their primary audio and video tracks—are downloaded. If additional media selections such as subtitles, closed captions, or alternative audio tracks are found, the session delegate’s URLSession:assetDownloadTask:didResolveMediaSelection: method is called, indicating that additional media selections exist on the server. To download additional media selections, save a reference to this resolved AVMediaSelection object so you can create subsequent download tasks to be executed serially.
    internal var resolvedMediaSelection: AVMediaSelection?
    
    fileprivate var task: AVAssetDownloadTask?
    internal var configuration: Configuration
    fileprivate var fairplayRequester: DownloadFairplayRequester?
    fileprivate let sessionManager: SessionManager
    
    internal var urlAsset: AVURLAsset? {
        return task?.urlAsset
    }
    
    internal lazy var delegate: DownloadTaskDelegate = { [unowned self] in
        return DownloadTaskDelegate(task: self)
        }()
    
    
    /// New, fresh DownloadTasks
    internal init(sessionManager: SessionManager, configuration: Configuration, fairplayRequester: DownloadFairplayRequester? = nil) {
        self.sessionManager = sessionManager
        self.configuration = configuration
        self.fairplayRequester = fairplayRequester
    }
    
    internal init(restoredTask: AVAssetDownloadTask, sessionManager: SessionManager, configuration: Configuration, fairplayRequester: DownloadFairplayRequester? = nil) {
        self.task = restoredTask
        self.sessionManager = sessionManager
        self.configuration = configuration
        self.fairplayRequester = fairplayRequester
    }
    
    // Controls
    public func resume() {
        // AVAssetDownloadTask provides the ability to resume previously stopped downloads under certain circumstances. To do so, simply instantiate a new AVAssetDownloadTask with an AVURLAsset instantiated with a file NSURL pointing to the partially downloaded bundle with the desired download options, and the download will continue restoring any previously downloaded data. FPS keys remain encrypted in persisted form during this process.
        guard let task = task else {
            print("⚠️ Resume called on DownloadTask in preparation")
            return
        }
        task.resume()
        onResumed(self)
    }
    
    public func prepare() { // TODO: Possibly remove this
        if task != nil {
            print("⚠️ Prepare called on DownloadTask with an attached AVAssetDownloadTask")
            print("👍 DownloadTask prepared")
            onPrepared(self)
            
            if autoStart {
                resume()
            }
            return
        }
//        restoreSuspendedTask(for: configuration) { [weak self] success in
//            guard let weakSelf = self else { return }
//            if !success {
//                weakSelf.createNewTask(with: weakSelf.configuration)
//            }
//        }
        createNewTask(with: configuration)
    }
    
//    private func restoreSuspendedTask(for configuration: Configuration, callback: @escaping (Bool) -> Void) {
//        print("♻️ Attempting to restore previous DownloadTask for: \(configuration.assetId)")
//        sessionManager.task(assetId: configuration.assetId) { [weak self] task in
//            guard let weakSelf = self else {
//                return
//            }
//            guard let task = task else {
//                print("⚠️ No DownloadTask to restore for: \(weakSelf.configuration.assetId)")
//                callback(false)
//                return
//            }
//            print("♻️ Restored DownloadTask associated with request for: \(weakSelf.configuration.assetId)")
//            
//            weakSelf.finalizePreparation(of: task)
//        }
//    }
    
    private func createNewTask(with configuration: Configuration) {
        print("✅ Creating new DownloadTask for: \(configuration.assetId)")
        // Create a fresh task
        let options = requiredBitrate != nil ? [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: requiredBitrate!] : nil
        
        startTask(with: options) { error in
            if let error = error {
                onError(self, configuration.destination, error)
                return
            }
        }
    }
    
    internal func startTask(with options: [String: Any]?, callback: (DownloadError?) -> Void) {
            if #available(iOS 10.0, *) {
                guard let task = sessionManager
                    .session
                    .makeAssetDownloadTask(asset: AVURLAsset(url: configuration.url),
                                           assetTitle: configuration.assetId,
                                           assetArtworkData: configuration.artwork,
                                           options: options) else {
                                            // This method may return nil if the AVAssetDownloadURLSession has been invalidated.
                                            callback(.downloadSessionInvalidated)
                                            return
                }
                task.taskDescription = configuration.assetId
                finalizePreparation(of: task)
                callback(nil)
            }
            else {
                guard let destination = configuration.destination else {
                    onError(self, configuration.destination, .failedToStartTaskWithoutDestination)
                    return
                }
                guard let task = sessionManager
                    .session
                    .makeAssetDownloadTask(asset: AVURLAsset(url: configuration.url),
                                           destinationURL: destination,
                                           options: options) else {
                                            // This method may return nil if the URLSession has been invalidated
                                            callback(.downloadSessionInvalidated)
                                            return
                }
                task.taskDescription = configuration.assetId
                finalizePreparation(of: task)
                callback(nil)
            }
    }
    
    private func finalizePreparation(of task: AVAssetDownloadTask) {
        self.task = task
        if fairplayRequester != nil {
            if task.urlAsset.resourceLoader.delegate != nil {
                task.urlAsset.resourceLoader.setDelegate(nil, queue: nil)
            }
            let queue = DispatchQueue(label: configuration.assetId + "-offlineFairplayLoader")
            
            task.urlAsset.resourceLoader.preloadsEligibleContentKeys = true
            task.urlAsset
                .resourceLoader
                .setDelegate(fairplayRequester, queue: queue)
        }
        
        sessionManager.delegate[task] = self
        
        print("👍 DownloadTask prepared")
        onPrepared(self)
        
        if autoStart {
            resume()
        }
    }
    
    public func suspend() {
        // If a download has been started, it can be stopped. AVAssetDownloadTask inherits from NSURLSessionTask, and downloads can be suspended or cancelled using the corresponding methods inherited from NSURLSessionTask. In the case where a download is stopped and there is no intention of resuming it, apps are responsible for deleting the portion of the asset already downloaded to a user’s device. The NSURLSessionTask documentation on developer.apple.com contains more details about this process.
        
        guard let task = self.task else { return }
        task.suspend()
        onSuspended(self)
    }
    
    /// NOTE: Canceling a download in progress will trigger `assetDownloadTask:didFinishDownloadingTo`. That `URL` can be used to "resume" the download at a later time.
    public func cancel() {
        // Downloaded HLS assets can be deleted using [NSFileManager removeItemAtURL:] with the URL for the downloaded version of the asset. In addition, if a user deletes the app that downloaded the HLS assets, they will also delete all content that the app stored to disk.
        
        guard let task = self.task else { return }
        task.cancel()
//        switch task.state {
//        case .suspended:
//            task.resume()
//            task.cancel()
//        default:
//            task.cancel()
//        }
        
        // NOTE: `onCanceled` called once `didCompleteWithError` delegate methods is triggered
    }
    
    // Configuration
    fileprivate var requiredBitrate: Int64?
    
    /// The lowest media bitrate greater than or equal to this value will be selected. If no suitable media bitrate is found, the highest media bitrate will be selected. If this option is not specified, the highest media bitrate will be selected for download by default.
    ///
    /// - parameter bitrate: The bitrate to select, in bps (bits per second)
    @discardableResult
    public func use(bitrate: Int64?) -> DownloadTask {
        requiredBitrate = bitrate
        return self
    }
    
    fileprivate var autoStart: Bool = true
    @discardableResult
    public func should(autoStart: Bool = true) -> DownloadTask {
        self.autoStart = autoStart
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
        guard let state = task?.state else { return .notStarted }
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
    internal var onPrepared: (DownloadTask) -> Void = { _ in }
    internal var onStarted: (DownloadTask) -> Void = { _ in }
    internal var onSuspended: (DownloadTask) -> Void = { _ in }
    internal var onResumed: (DownloadTask) -> Void = { _ in }
    internal var onCanceled: (DownloadTask, URL) -> Void = { _ in }
    internal var onCompleted: (DownloadTask, URL) -> Void = { _ in }
    internal var onProgress: (DownloadTask, Progress) -> Void = { _ in }
    internal var onError: (DownloadTask, URL?, DownloadError) -> Void = { _ in }
    internal var onPlaybackReady: (DownloadTask, URL) -> Void = { _ in }
    internal var onShouldDownloadMediaOption: ((DownloadTask, AdditionalMedia) -> MediaOption?) = { _ in return nil }
    internal var onDownloadingMediaOption: (DownloadTask, MediaOption) -> Void = { _ in }
}

extension DownloadTask {
    /// Returns currently downloaded subtitles
    @available(iOS 10.0, *)
    public var localSubtitles: [MediaOption] {
        return urlAsset?.localSubtitles ?? []
    }
    
    /// Returns currently downloaded subtitles
    @available(iOS 10.0, *)
    public var localAudio: [MediaOption] {
        return urlAsset?.localAudio ?? []
    }
    
    /// Returns currently downloaded subtitles
    @available(iOS 10.0, *)
    public var localVideo: [MediaOption] {
        return urlAsset?.localVideo ?? []
    }
}

extension DownloadTask: DownloadEventPublisher {
    public typealias DownloadEventProgress = Progress
    public typealias DownloadEventError = DownloadError
    
    @discardableResult
    public func onPrepared(callback: @escaping (DownloadTask) -> Void) -> DownloadTask {
        onPrepared = callback
        return self
    }
    
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
    public func onCanceled(callback: @escaping (DownloadTask, URL) -> Void) -> DownloadTask {
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
    public func onError(callback: @escaping (DownloadTask, URL?, DownloadError) -> Void) -> DownloadTask {
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
