//
//  AnalyticsConnector.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-11-08.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation


public protocol TaskAnalyticsProvider {
    func bind(connector: TaskAnalyticsConnector)
}

open class TaskAnalyticsConnector {
    public let provider: TaskAnalyticsProvider?
    public init(provider: TaskAnalyticsProvider?) {
        self.provider = provider
        provider?.bind(connector: self)
    }
    
    internal var onDownloadStarted: (Task) -> Void = { _ in }
    open func downloadStartedEvent(callback: @escaping (Task) -> Void) {
        onDownloadStarted = callback
    }
    
    internal var onDownloadPaused: (Task) -> Void = { _ in }
    open func downloadPausedEvent(callback: @escaping (Task) -> Void) {
        onDownloadPaused = callback
    }
    
    internal var onDownloadResumed: (Task) -> Void = { _ in }
    open func downloadResumedEvent(callback: @escaping (Task) -> Void) {
        onDownloadResumed = callback
    }
    
    internal var onDownloadCancelled: (Task) -> Void = { _ in }
    open func downloadCancelledEvent(callback: @escaping (Task) -> Void) {
        onDownloadCancelled = callback
    }
    
    internal  var onDownloadStopped: (Task) -> Void = { _ in }
    open func downloadStoppedEvent(callback: @escaping (Task) -> Void) {
        onDownloadStopped = callback
    }
    
    internal var onDownloadCompleted: (Task) -> Void = { _ in }
    open func downloadCompletedEvent(callback: @escaping (Task) -> Void) {
        onDownloadCompleted = callback
    }
    
    
    /// Triggered if the download process encounters an error during its lifetime
    ///
    /// - parameter task: `ExposureDownloadTask` broadcasting the event
    /// - parameter error: `ExposureError` causing the event to fire
    internal var onDownloadError: (Task, Error) -> Void = { _,_  in }
    open func downloadErrorEvent(callback: @escaping (Task, Error) -> Void) {
        onDownloadError = callback
    }
}
