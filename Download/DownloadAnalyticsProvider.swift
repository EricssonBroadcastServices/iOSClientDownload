//
//  DownloadAnalyticsProvider.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-11-07.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

public protocol DownloadAnalyticsProvider {
    //    associatedtype DownloadTask: TaskType
    
    //    // Playback.DownloadStarted, VideoLength, DownloadedSize, MediaSize, AssetId
    //    func downloadStartedEvent<T>(task: T) where T : TaskType
    //
    //    // Playback.DownloadPaused, DownloadedSize, MediaSize, AssetId
    //    func downloadPausedEvent<T: TaskType>(task: T)
    //
    //    // Playback.DownloadResumed, DownloadedSize, MediaSize, AssetId
    //    func downloadResumedEvent<T: TaskType>(task: T)
    //
    //    // Playback.DownloadCancelled, DownloadedSize, MediaSize, AssetId, OffsetTime
    //    func downloadCancelledEvent<T: TaskType>(task: T)
    //
    //    // Playback.DownloadStopped, DownloadedSize, MediaSize, AssetId, OffsetTime
    //    func downloadStoppedEvent<T: TaskType>(task: T)
    //
    //    // Playback.DownloadCompleted, DownloadedSize, MediaSize, AssetId, OffsetTime
    //    func downloadCompletedEvent<T: TaskType>(task: T)
    //
    //
    //    /// Triggered if the download process encounters an error during its lifetime
    //    ///
    //    /// - parameter task: `TaskType` broadcasting the event
    //    /// - parameter error: `DownloadError` causing the event to fire
    //    func downloadErrorEvent<T: TaskType>(task: T, error: DownloadError)
}
