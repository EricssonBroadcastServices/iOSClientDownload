//
//  Downloader.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-09.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

//public struct OfflineMediaAsset {
//    /// Returns the download task if download is not complete
//    public var downloadTask: DownloadTask? { }
//    
//    /// Deletes locally stored asset data
//    public func delete() { }
//}

public enum DownloadError: Error {
    case generalError(error: Error)
    
    case storageUrlNotFound
    case completedWithError(error: Error)
    case failedToDeleteMedia(error: Error)
    case canceledTaskFailedToDeleteLocalMedia
    case downloadSessionInvalidated
}

public protocol OfflineFairplayRequester: AVAssetResourceLoaderDelegate {
    
}

public final class DownloadTask {
    public struct Progress {
        /// Size in bytes
        public let size: Int64
        
        /// Total size in bytes
        public let total: Int64

        /// Percentage downloaded
        public let percentage: Double
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
    fileprivate var resolvedMediaSelection: AVMediaSelection?
    
    fileprivate var urlAsset: AVURLAsset
    fileprivate var configuration: Configuration
    fileprivate var fairplayRequester: OfflineFairplayRequester?
    
    fileprivate let sessionConfiguration: URLSessionConfiguration
    fileprivate var task: AVAssetDownloadTask?
    
    fileprivate lazy var session: AVAssetDownloadURLSession = { [unowned self] in
        // Create the AVAssetDownloadURLSession using the configuration.
        return AVAssetDownloadURLSession(configuration: self.sessionConfiguration,
                                         assetDownloadDelegate: self.delegate,
                                         delegateQueue: OperationQueue.main)
    }()
    
    fileprivate lazy var delegate: DownloadDelegate = { [unowned self] in
        return DownloadDelegate(task: self)
    }()
    
    internal init(configuration: Configuration) {
        self.configuration = configuration
        
        // Create the configuration for the AVAssetDownloadURLSession.
        sessionConfiguration = URLSessionConfiguration.background(withIdentifier: configuration.name + "-assetDownloadURLSession") // TODO: Should the configuration be per downloadTask or per `Download` module. IE do we use one per download or one for the entire module?
        
        urlAsset = AVURLAsset(url: configuration.url)
    }
    
    // MARK: FairPlay
    public func fairplay(requester: OfflineFairplayRequester) -> DownloadTask {
        fairplayRequester = requester
        urlAsset.resourceLoader.setDelegate(requester, queue: DispatchQueue(label: configuration.name + "-offlineFairplayLoader"))
        return self
    }
    
    // Controls
    public func resume() {
        // AVAssetDownloadTask provides the ability to resume previously stopped downloads under certain circumstances. To do so, simply instantiate a new AVAssetDownloadTask with an AVURLAsset instantiated with a file NSURL pointing to the partially downloaded bundle with the desired download options, and the download will continue restoring any previously downloaded data. FPS keys remain encrypted in persisted form during this process.
        if task == nil {
            initialDownload()
        }
        else {
            task?.resume()
            onResumed(self)
        }
    }
    
    fileprivate func initialDownload() {
        // Fetch the targeted bitrate
        let options = requiredBitrate != nil ? [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: requiredBitrate!] : nil
        
        startTask(with: options) { error in
            guard error == nil else {
                onError(self, error!)
                return
            }
            onStarted(self)
        }
    }
    
    /// NOTE: Can/will replacing the previous task cause problems? Investigate
    fileprivate func startTask(with options: [String: Any]?, callback: (DownloadError?) -> Void) {
        if #available(iOS 10.0, *) {
            guard let task = session.makeAssetDownloadTask(asset: urlAsset,
                                                           assetTitle: configuration.name,
                                                           assetArtworkData: configuration.artwork,
                                                           options: options) else {
                // This method may return nil if the AVAssetDownloadURLSession has been invalidated.
                callback(.downloadSessionInvalidated)
                return
            }
            self.task = task
            task.taskDescription = configuration.name
            
            task.resume()
        }
        else {
            guard let destination = configuration.destination else {
                onError(self, .storageUrlNotFound)
                return
            }
            
            guard let task = session.makeAssetDownloadTask(asset: urlAsset,
                                                           destinationURL: destination,
                                                           options: options) else {
                // This method may return nil if the URLSession has been invalidated
                callback(.downloadSessionInvalidated)
                return
            }
            
            self.task = task
            task.taskDescription = configuration.name
            
            task.resume()
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
    @discardableResult
    public func use(bitrate: Int64?) -> Self {
        requiredBitrate = bitrate
        return self
    }
    
    @discardableResult
    public func allow(cellularAccess: Bool) -> Self {
        sessionConfiguration.allowsCellularAccess = cellularAccess
        return self
    }
    
    // State
//    public var currentProgress: Progress {
//        ?????
//    }
    
    // MARK: DownloadEventPublisher
    fileprivate var onStarted: (DownloadTask) -> Void = { _ in }
    fileprivate var onSuspended: (DownloadTask) -> Void = { _ in }
    fileprivate var onResumed: (DownloadTask) -> Void = { _ in }
    fileprivate var onCanceled: (DownloadTask) -> Void = { _ in }
    fileprivate var onCompleted: (DownloadTask, URL) -> Void = { _ in }
    fileprivate var onProgress: (DownloadTask, Progress) -> Void = { _ in }
    fileprivate var onError: (DownloadTask, DownloadError) -> Void = { _ in }
    fileprivate var onPlaybackReady: (DownloadTask, URL) -> Void = { _ in }
    fileprivate var onShouldDownloadMediaOption: ((DownloadTask, AdditionalMedia) -> MediaOption?) = { _ in return nil }
    fileprivate var onDownloadingMediaOption: (DownloadTask, MediaOption) -> Void = { _ in }
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

internal class DownloadDelegate: NSObject {
    internal unowned let downloadTask: DownloadTask
    
    internal init(task: DownloadTask) {
        downloadTask = task
    }
}

extension DownloadDelegate: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            // Error
            if let nsError = error as? NSError {
                switch (nsError.domain, nsError.code) {
                case (NSURLErrorDomain, NSURLErrorCancelled):
                    // This task was canceled by user. URL was saved from
                    guard let location = downloadTask.configuration.destination else {
                        downloadTask.onError(downloadTask, .canceledTaskFailedToDeleteLocalMedia)
                        return
                    }
                    
                    do {
                        try FileManager.default.removeItem(at: location)
                        downloadTask.configuration.destination = nil
                        downloadTask.onCanceled(downloadTask)
                    }
                    catch {
                        downloadTask.onError(downloadTask, .failedToDeleteMedia(error: error))
                    }
                default:
                    downloadTask.onError(downloadTask, .completedWithError(error: error))
                }
            }
            else {
                downloadTask.onError(downloadTask, .completedWithError(error: error))
            }
        }
        else {
            // Success
            guard let resolvedMedia = downloadTask.resolvedMediaSelection else {
                // 1. No more media available. Trigger onCompleted
                finalizeDownload()
                return
            }
            
            // 2. Ask, by callback, if and which additional AVMediaSelectionOption's should be included
            if let newSelection = downloadTask.onShouldDownloadMediaOption(downloadTask, AdditionalMedia(asset: downloadTask.urlAsset)) {
                // 2.1 User indicated additional media is requested
                let currentMediaOption = resolvedMedia.mutableCopy() as! AVMutableMediaSelection
                
                currentMediaOption.select(newSelection.option, in: newSelection.group)
                
                let options = [AVAssetDownloadTaskMediaSelectionKey: currentMediaOption]
                
                downloadTask.startTask(with: options) { [unowned self] error in
                    guard error == nil else {
                        self.downloadTask.onError(self.downloadTask, error!)
                        return
                    }
                    self.downloadTask.onDownloadingMediaOption(self.downloadTask, newSelection)
                }
            }
            else {
                // 2.2 No additional media was requested
                finalizeDownload()
            }
        }
        
    }
    
    private func finalizeDownload() {
        guard let location = downloadTask.configuration.destination else {
            // 3. Error when no storage url is found
            downloadTask.onError(downloadTask, .storageUrlNotFound)
            return
        }
        
        downloadTask.onCompleted(downloadTask, location)
    }
}

extension DownloadDelegate: AVAssetDownloadDelegate {
    /// NOTE: Will also be called when a partially downloaded asset is cancelled by the user
    /// Also called onError?
    ///
    /// This delegate callback should only be used to save the location URL somewhere in your application. Any additional work should be done in `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        
        // This is the location to save
        // let locationToSave = location.relativePath
        downloadTask.configuration.destination = location
    }
    
    @available(iOS 9.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var percentComplete = 0.0

        for range in loadedTimeRanges {
            let loadedTimeRange = range.timeRangeValue
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }

        // TODO: unfinished calculations for size and totalSize
        let progress = DownloadTask.Progress(size: -1,
                                             total: -1,
                                             progress: percentComplete * 100)
        downloadTask.onProgress(downloadTask, progress)
    }
    
    @available(iOS 9.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        downloadTask.resolvedMediaSelection = resolvedMediaSelection
    }
}

public protocol DownloadEventPublisher {
    associatedtype DownloadEventProgress
    associatedtype DownloadEventError
    
    func onStarted(callback: @escaping (Self) -> Void) -> Self
    
    func onSuspended(callback: @escaping (Self) -> Void) -> Self
    
    func onResumed(callback: @escaping (Self) -> Void) -> Self
    
    func onCanceled(callback: @escaping (Self) -> Void) -> Self
    
    func onCompleted(callback: @escaping (Self, URL) -> Void) -> Self
    
    func onProgress(callback: @escaping (Self, DownloadEventProgress) -> Void) -> Self
    
    func onError(callback: @escaping (Self, DownloadEventError) -> Void) -> Self
    
    func onPlaybackReady(callback: @escaping (Self, URL) -> Void) -> Self
    
    func onShouldDownloadMediaOption(callback: @escaping (Self, AdditionalMedia) -> MediaOption?) -> Self
    
    func onDownloadingMediaOption(callback: @escaping (Self, MediaOption) -> Void) -> Self
}

public struct MediaOption: Equatable {
    internal let group: AVMediaSelectionGroup
    public let option: AVMediaSelectionOption
    
    public static func == (lhs: MediaOption, rhs: MediaOption) -> Bool {
        return lhs.group == rhs.group && lhs.option == rhs.option
    }
}

extension AVURLAsset {
    // MARK: Subtitles
    private var subtitleGroup: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicLegible)
    }
    
    var availableSubtitles: [MediaOption] {
        guard let group = subtitleGroup else { return [] }
        return group.options.map{ MediaOption(group: group, option: $0) }
    }
    
    /// TODO: How do we find out the *locally* stored media in iOS 9.0?
    @available(iOS 10.0, *)
    var localSubtitles: [MediaOption] {
        guard let group = subtitleGroup else { return [] }
        return assetCache?.mediaSelectionOptions(in: group).map{ MediaOption(group: group, option: $0) } ?? []
    }
    
    // MARK: Audio
    private var audioGroup: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible)
    }
    
    var availableAudio: [MediaOption] {
        guard let group = audioGroup else { return [] }
        return group.options.map{ MediaOption(group: group, option: $0) }
    }
    
    /// TODO: How do we find out the *locally* stored media in iOS 9.0?
    @available(iOS 10.0, *)
    var localAudio: [MediaOption] {
        guard let group = audioGroup else { return [] }
        return assetCache?.mediaSelectionOptions(in: group).map{ MediaOption(group: group, option: $0) } ?? []
    }
    
    // MARK: Video
    private var videoGroup: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicVisual)
    }
    
    var availableVideo: [MediaOption] {
        guard let group = videoGroup else { return [] }
        return group.options.map{ MediaOption(group: group, option: $0) }
    }
    
    /// TODO: How do we find out the *locally* stored media in iOS 9.0?
    @available(iOS 10.0, *)
    var localVideo: [MediaOption] {
        guard let group = videoGroup else { return [] }
        return assetCache?.mediaSelectionOptions(in: group).map{ MediaOption(group: group, option: $0) } ?? []
    }
}

public struct AdditionalMedia {
    internal let asset: AVURLAsset
    
    public var subtitles: [MediaOption] {
        if #available(iOS 10.0, *) {
            let local = asset.localSubtitles
            return asset.availableSubtitles.filter{ !local.contains($0) }
        }
        else {
            return asset.availableSubtitles
        }
    }
    
    public var audio: [MediaOption] {
        if #available(iOS 10.0, *) {
            let local = asset.localAudio
            return asset.availableAudio.filter{ !local.contains($0) }
        }
        else {
            return asset.availableAudio
        }
    }
    
    public var video: [MediaOption] {
        if #available(iOS 10.0, *) {
            let local = asset.localVideo
            return asset.availableVideo.filter{ !local.contains($0) }
        }
        else {
            return asset.availableVideo
        }
    }
}

public struct Downloader {
    @available(iOS 10.0, *)
    public static func download(mediaLocator: URL, named name: String = UUID().uuidString, artwork artworkData: Data? = nil) -> DownloadTask {
        let configuration = DownloadTask.Configuration(url: mediaLocator,
                                                       name: name,
                                                       artwork: artworkData,
                                                       destination: nil)
        return DownloadTask(configuration: configuration)
    }
    
    @available(iOS, introduced: 9.0, deprecated: 10.0)
    public static func download(mediaLocator: URL, to destination: URL) -> DownloadTask {
        let configuration = DownloadTask.Configuration(url: mediaLocator,
                                                       name: UUID().uuidString,
                                                       artwork: nil,
                                                       destination: destination)
        return DownloadTask(configuration: configuration)
    }
    
//    public static func offline(assetId: String) -> OfflineMediaAsset? { }
}
