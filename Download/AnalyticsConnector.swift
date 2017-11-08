//
//  AnalyticsConnector.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-11-08.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

open class AnalyticsConnector<T: TaskType, Provider>: AnalyticsConnectorType {
    public var provider: Provider
    public init(provider: Provider) {
        self.provider = provider
    }
    
    // Playback.DownloadStarted, VideoLength, DownloadedSize, MediaSize, AssetId
    public var onDownloadStarted: (T) -> Void = { _ in }
    open func downloadStartedEvent(callback: @escaping (T) -> Void) {
        onDownloadStarted = callback
    }
    
    // Playback.DownloadPaused, DownloadedSize, MediaSize, AssetId
    public var onDownloadPaused: (T) -> Void = { _ in }
    open func downloadPausedEvent(callback: @escaping (T) -> Void) {
        onDownloadPaused = callback
    }
    
    // Playback.DownloadResumed, DownloadedSize, MediaSize, AssetId
    public var onDownloadResumed: (T) -> Void = { _ in }
    open func downloadResumedEvent(callback: @escaping (T) -> Void) {
        onDownloadResumed = callback
    }
    
    // Playback.DownloadCancelled, DownloadedSize, MediaSize, AssetId, OffsetTime
    public var onDownloadCancelled: (T) -> Void = { _ in }
    open func downloadCancelledEvent(callback: @escaping (T) -> Void) {
        onDownloadCancelled = callback
    }
    
    // Playback.DownloadStopped, DownloadedSize, MediaSize, AssetId, OffsetTime
    public  var onDownloadStopped: (T) -> Void = { _ in }
    open func downloadStoppedEvent(callback: @escaping (T) -> Void) {
        onDownloadStopped = callback
    }
    
    // Playback.DownloadCompleted, DownloadedSize, MediaSize, AssetId, OffsetTime
    public var onDownloadCompleted: (T) -> Void = { _ in }
    open func downloadCompletedEvent(callback: @escaping (T) -> Void) {
        onDownloadCompleted = callback
    }
    
    
    /// Triggered if the download process encounters an error during its lifetime
    ///
    /// - parameter task: `ExposureDownloadTask` broadcasting the event
    /// - parameter error: `ExposureError` causing the event to fire
    public var onDownloadError: (T, T.DownloadEventError) -> Void = { _ in }
    open func downloadErrorEvent(callback: @escaping (T, T.DownloadEventError) -> Void) {
        onDownloadError = callback
    }
}
