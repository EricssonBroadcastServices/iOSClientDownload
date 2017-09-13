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
    case downloadSessionInvalidated
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
        let name: String
        let artwork: Data?
        
        /// location.bookmarkData()
        /// Bookmark data should be used when persisting this url to disk
        ///
        /// - important: destination URL will be handled diffrently on iOS 9 vs iOS 10. On the later version, storage url for local media is handled and assigned by the system. In iOS 9 this path is supplied by the user.
        var destination: URL?
    }
    
    
    ///
    fileprivate var resolvedMediaSelection: AVMediaSelection?
    
    fileprivate var urlAsset: AVURLAsset
    fileprivate var configuration: Configuration
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
        sessionConfiguration = URLSessionConfiguration.background(withIdentifier: "EMP-Identifier")
        
        urlAsset = AVURLAsset(url: configuration.url)
    }
    
    // Controls
    public func resume() {
        // AVAssetDownloadTask provides the ability to resume previously stopped downloads under certain circumstances. To do so, simply instantiate a new AVAssetDownloadTask with an AVURLAsset instantiated with a file NSURL pointing to the partially downloaded bundle with the desired download options, and the download will continue restoring any previously downloaded data. FPS keys remain encrypted in persisted form during this process.
        
    }
    
    fileprivate func initialDownload() {
        // Fetch the targeted bitrate
        let options = requiredBitrate != nil ? [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: requiredBitrate!] : nil
        
        if #available(iOS 10.0, *) {
            guard let task = session.makeAssetDownloadTask(asset: urlAsset,
                                                           assetTitle: configuration.name,
                                                           assetArtworkData: configuration.artwork,
                                                           options: options) else {
                // This method may return nil if the AVAssetDownloadURLSession has been invalidated.
                onError(self, .downloadSessionInvalidated)
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
                onError(self, .downloadSessionInvalidated)
                return
            }
            
            self.task = task
            task.taskDescription = configuration.name
            
            task.resume()
        }
    }
    
    
//        if let mediaSelection = self.resolvedMediaSelection {
//            options[AVAssetDownloadTaskMediaSelectionKey] = mediaSelection
//        }
    
    public func suspend() {
        // If a download has been started, it can be stopped. AVAssetDownloadTask inherits from NSURLSessionTask, and downloads can be suspended or cancelled using the corresponding methods inherited from NSURLSessionTask. In the case where a download is stopped and there is no intention of resuming it, apps are responsible for deleting the portion of the asset already downloaded to a user’s device. The NSURLSessionTask documentation on developer.apple.com contains more details about this process.
        
    }
    
    public func cancel() {
        // Downloaded HLS assets can be deleted using [NSFileManager removeItemAtURL:] with the URL for the downloaded version of the asset. In addition, if a user deletes the app that downloaded the HLS assets, they will also delete all content that the app stored to disk.
    }
    
    // Configuration
    fileprivate var requiredBitrate: Int64?
    public func use(bitrate: Int64?) -> Self {
        requiredBitrate = bitrate
        return self
    }
    
    public func allow(cellularAccess: Bool) -> Self {
        // URLSessionConfiguration.allowsCellularAccess
        // AVAssetDownloadURLSession(configuration: backgroundConfiguration, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
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
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            // Error
            if let nsError = error as? NSError {
                switch (nsError.domain, nsError.code) {
                case (NSURLErrorDomain, NSURLErrorCancelled):
                    // This task was canceled by user. URL was saved from `urlSession(_:assetDownloadTask:didFinishDownloadingTo:)`. Perform cleanup
                    guard let location = downloadTask.configuration.destination else {
                        // TODO: Should we throw an error here when the local assets could not be found?
                        downloadTask.onError(downloadTask, .storageUrlNotFound)
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
            
            // 1. Ask, by callback, if and which additional AVMediaSelectionOption's should be included
            
            
            // 2. if done, Trigger onCompleted
            
            //            downloadTask.onCompleted(downloadTask, location)
        }
        
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
}

public struct AdditionalSubtitle {
    internal let group: AVMediaSelectionGroup
    public let option: AVMediaSelectionOption
}

public struct AdditionalVideo {
    internal let group: AVMediaSelectionGroup
    public let option: AVMediaSelectionOption
}

public struct AdditionalAudio {
    internal let group: AVMediaSelectionGroup
    public let option: AVMediaSelectionOption
}

extension AVURLAsset {
    var availableSubtitles: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicLegible)
    }
    
    var availableAudioTracks: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible)
    }
    
    var availableVideoTracks: AVMediaSelectionGroup? {
        return mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicVisual)
    }
}

public struct AdditionalMedia {
    internal let asset: AVURLAsset
    
    public var subtitles: [AdditionalSubtitle] {
        guard let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicLegible) else { return [] }
        
        let mediaOptions = avaliableOptions(for: group)
        
        return mediaOptions.map{ AdditionalSubtitle(group: group, option: $0) }
    }
    
    public var audio: [AdditionalAudio] {
        guard let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicAudible) else { return [] }
        
        let mediaOptions = avaliableOptions(for: group)
        
        return mediaOptions.map{ AdditionalAudio(group: group, option: $0) }
    }
    
    public var video: [AdditionalVideo] {
        guard let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristicVisual) else { return [] }
        
        let mediaOptions = avaliableOptions(for: group)
        
        return mediaOptions.map{ AdditionalVideo(group: group, option: $0) }
    }
    
    private func avaliableOptions(for group: AVMediaSelectionGroup) -> [AVMediaSelectionOption] {
        let options = group.options
        if #available(iOS 10.0, *), let cache = asset.assetCache {
            let savedOptions = cache.mediaSelectionOptions(in: group)
            
            return options.filter{ !savedOptions.contains($0) }
        }
        else {
            return options
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
