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
    
    case noDestinationURL
}

public final class DownloadTask {
    public struct Progress {
        /// Size in bytes
        public let size: Int64
        
        /// Total size in bytes
        public let total: Int64
    }
    
    internal struct Configuration {
        let url: URL
        let name: String?
        let artwork: Data?
    }
    
    fileprivate let configuration: Configuration
    fileprivate var task: AVAssetDownloadTask?
    fileprivate var session: AVAssetDownloadURLSession?
    
    internal init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    // Controls
    public func resume() {
        // AVAssetDownloadTask provides the ability to resume previously stopped downloads under certain circumstances. To do so, simply instantiate a new AVAssetDownloadTask with an AVURLAsset instantiated with a file NSURL pointing to the partially downloaded bundle with the desired download options, and the download will continue restoring any previously downloaded data. FPS keys remain encrypted in persisted form during this process.
        
    }
    
    public func suspend() {
        // If a download has been started, it can be stopped. AVAssetDownloadTask inherits from NSURLSessionTask, and downloads can be suspended or cancelled using the corresponding methods inherited from NSURLSessionTask. In the case where a download is stopped and there is no intention of resuming it, apps are responsible for deleting the portion of the asset already downloaded to a user’s device. The NSURLSessionTask documentation on developer.apple.com contains more details about this process.
        
    }
    
    public func cancel() {
        // Downloaded HLS assets can be deleted using [NSFileManager removeItemAtURL:] with the URL for the downloaded version of the asset. In addition, if a user deletes the app that downloaded the HLS assets, they will also delete all content that the app stored to disk.
    }
    
    // Configuration
    fileprivate var requiredBitrate: Int64?
    public func use(bitrate: Int64?) -> Self {
        // assetDownloadURLSession.makeAssetDownloadTask(asset: asset.urlAsset, assetTitle: asset.name, assetArtworkData: nil, options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265000])
        requiredBitrate = bitrate
        return self
    }
    
    fileprivate var mediaSelection: AVMediaSelection?
    public func use(mediaSelection: AVMediaSelection) -> Self {
        // The media selection can be set on a AVAssetDownloadTask object using the AVAssetDownloadTaskMediaSelectionKey.
        self.mediaSelection = mediaSelection
        return self
    }
    
    fileprivate var cellularAccess: Bool = false
    public func allow(cellularAccess: Bool) -> Self {
        // URLSessionConfiguration.allowsCellularAccess
        // AVAssetDownloadURLSession(configuration: backgroundConfiguration, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
        self.cellularAccess = cellularAccess
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
}

internal class DownloadDelegate: NSObject {
    internal unowned let downloadTask: DownloadTask
    
    internal init(task: DownloadTask) {
        downloadTask = task
    }
}

extension DownloadDelegate: URLSessionTaskDelegate {
    
    // Required for completion event if iOS < 10
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error == nil else {
            downloadTask.onError(downloadTask, .generalError(error: error!))
            return
        }
        
        if #available(iOS 9, *) {
            guard let destination = downloadTask.task?.destinationURL else {
                downloadTask.onError(downloadTask, .noDestinationURL)
                return
            }
            downloadTask.onCompleted(downloadTask, destination)
        }
        
    }
}
extension DownloadDelegate: AVAssetDownloadDelegate {
    // @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        downloadTask.onCompleted(downloadTask, location)
    }
    
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        
    }
    
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        
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
}

public struct Downloader {
    public static func download(mediaLocator: URL, named name: String = UUID().uuidString, artwork artworkData: Data? = nil) -> DownloadTask {
        let configuration = DownloadTask.Configuration(url: mediaLocator,
                                                       name: name,
                                                       artwork: artworkData)
        return DownloadTask(configuration: configuration)
    }
    
//    public static func offline(assetId: String) -> OfflineMediaAsset? { }
}
