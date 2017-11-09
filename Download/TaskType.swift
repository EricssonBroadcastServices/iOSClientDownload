//
//  DownloadTaskType.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-19.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public protocol TaskType: class, EventPublisher {
    var configuration: Configuration { get }
    var responseData: ResponseData { get }
    var sessionManager: SessionManager<Self> { get }
    var delegate: TaskDelegate<Self> { get }
    var fairplayRequester: DownloadFairplayRequester? { get }
    var eventPublishTransmitter: EventPublishTransmitter<Self> { get }
    
    var task: AVAssetDownloadTask? { get }
    
    associatedtype DownloadState
    
    func resume()
    func suspend()
    func cancel()
    
    func use(bitrate: Int64?) -> Self
    var state: DownloadState { get }
}

extension TaskType {
    /// The lowest media bitrate greater than or equal to this value will be selected. If no suitable media bitrate is found, the highest media bitrate will be selected. If this option is not specified, the highest media bitrate will be selected for download by default.
    ///
    /// - parameter bitrate: The bitrate to select, in bps (bits per second)
    @discardableResult
    public func use(bitrate: Int64?) -> Self {
        configuration.requiredBitrate = bitrate
        return self
    }
}

extension TaskType {
    public func createAndConfigureTask(with options: [String: Any]?, using configuration: Configuration, callback: (AVAssetDownloadTask?, DownloadEventError?) -> Void) {
        guard let url = configuration.url else {
            callback(nil, .downloadError(reason: .targetUrlNotFound))
            return
        }
        
        if #available(iOS 10.0, *) {
            guard let task = sessionManager
                .session
                .makeAssetDownloadTask(asset: AVURLAsset(url: url),
                                       assetTitle: configuration.identifier,
                                       assetArtworkData: configuration.artwork,
                                       options: options) else {
                                        // This method may return nil if the AVAssetDownloadURLSession has been invalidated.
                                        callback(nil, .downloadError(reason: .downloadSessionInvalidated))
                                        return
            }
            task.taskDescription = configuration.identifier
            configureResourceLoader(for: task)
            callback(task,nil)
        }
        else {
            guard let destination = responseData.destination else {
                callback(nil, .downloadError(reason: .failedToStartTaskWithoutDestination))
                return
            }
            guard let task = sessionManager
                .session
                .makeAssetDownloadTask(asset: AVURLAsset(url: url),
                                       destinationURL: destination,
                                       options: options) else {
                                        // This method may return nil if the URLSession has been invalidated
                                        callback(nil, .downloadError(reason: .downloadSessionInvalidated))
                                        return
            }
            task.taskDescription = configuration.identifier
            configureResourceLoader(for: task)
            callback(task,nil)
        }
    }
    
    public func configureResourceLoader(for task: AVAssetDownloadTask) {
        if fairplayRequester != nil {
            if task.urlAsset.resourceLoader.delegate != nil {
                task.urlAsset.resourceLoader.setDelegate(nil, queue: nil)
            }
            let queue = DispatchQueue(label: configuration.identifier + "-offlineFairplayLoader")
            
            task.urlAsset.resourceLoader.preloadsEligibleContentKeys = true
            task.urlAsset
                .resourceLoader
                .setDelegate(fairplayRequester, queue: queue)
        }
    }
}

extension TaskType {
    public func handle(restoredTask: AVAssetDownloadTask) {
        print("👍 DownloadTask restored")
        
        switch restoredTask.state {
        case .running:
            eventPublishTransmitter.onPrepared(self)
            eventPublishTransmitter.onResumed(self)
        case .suspended:
            eventPublishTransmitter.onPrepared(self)
            eventPublishTransmitter.onSuspended(self)
        case .canceling:
            break
        case .completed:
            if let error = restoredTask.error {
                eventPublishTransmitter.onError(self, responseData.destination, .downloadError(reason: .completedWithError(error: error)))
            }
            else {
                // Handle completion
                if let destination = responseData.destination {
                    eventPublishTransmitter.onCompleted(self, destination)
                }
                else {
                    eventPublishTransmitter.onError(self, responseData.destination, .downloadError(reason: .completedWithoutValidStorageUrl))
                }
            }
        }
    }
}
