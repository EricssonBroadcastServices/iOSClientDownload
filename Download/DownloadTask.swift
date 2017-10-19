//
//  DownloadTask.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation


public struct Progress {
    /// Current progress measured in [0,1]
    public let current: Double
}

public final class DownloadTask: DownloadTaskType {
    
    public let eventPublishTransmitter = DownloadEventPublishTransmitter<DownloadTask>()
    
    public var task: AVAssetDownloadTask?
    public var configuration: Configuration
    public var progression: Progression
    public var fairplayRequester: DownloadFairplayRequester?
    public let sessionManager: SessionManager<DownloadTask>
    
    internal var urlAsset: AVURLAsset? {
        return task?.urlAsset
    }
    
    
    public lazy var delegate: DownloadTaskDelegate = { [unowned self] in
        return DownloadTaskDelegate(task: self)
        }()
    
    
    /// New, fresh DownloadTasks
    public init(sessionManager: SessionManager<DownloadTask>, configuration: Configuration, fairplayRequester: DownloadFairplayRequester? = nil, progression: Progression = Progression()) {
        self.sessionManager = sessionManager
        self.configuration = configuration
        self.fairplayRequester = fairplayRequester
        self.progression = progression
    }
    
    public init(restoredTask: AVAssetDownloadTask, sessionManager: SessionManager<DownloadTask>, configuration: Configuration, fairplayRequester: DownloadFairplayRequester? = nil, progression: Progression = Progression()) {
        self.task = restoredTask
        self.sessionManager = sessionManager
        self.configuration = configuration
        self.fairplayRequester = fairplayRequester
        self.progression = progression
    }
}

extension DownloadTask {
    /// - parameter lazily: `true` will delay creation of new tasks until the user calls `resume()`. `false` will force create the task if none exists.
    @discardableResult
    public func prepare(lazily: Bool = true) -> DownloadTask {
        guard let task = task else {
            restoreOrCreate(forceNew: !lazily)
            return self
        }
        // A task has been previously prepared, trigger the correct callbacks.
        handle(restoredTask: task)
        return self
    }
    
    fileprivate func restoreOrCreate(forceNew: Bool, callback: @escaping () -> Void = { _ in }) {
        sessionManager.restoreTask(with: configuration.identifier) { [weak self] restoredTask in
            guard let weakSelf = self else { return }
            if let restoredTask = restoredTask {
                weakSelf.configureResourceLoader(for: restoredTask)
                
                weakSelf.task = restoredTask
                weakSelf.sessionManager.delegate[restoredTask] = weakSelf
                
                weakSelf.handle(restoredTask: restoredTask)
            }
            else {
                if forceNew {
                    print("✅ No AVAssetDownloadTask prepared, creating new for: \(weakSelf.configuration.identifier)")
                    // Create a fresh task
                    let options = weakSelf.configuration.requiredBitrate != nil ? [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: weakSelf.configuration.requiredBitrate!] : nil
                    weakSelf.createAndConfigureTask(with: options, using: weakSelf.configuration) { urlTask, error in
                        if let error = error {
                            weakSelf.eventPublishTransmitter.onError(weakSelf, weakSelf.progression.destination, error)
                            return
                        }
                        
                        if let urlTask = urlTask {
                            weakSelf.task = urlTask
                            weakSelf.sessionManager.delegate[urlTask] = weakSelf
                            print("👍 DownloadTask prepared")
                            weakSelf.eventPublishTransmitter.onPrepared(weakSelf)
                        }
                    }
                }
            }
            callback()
        }
    }
    
    // MARK: Controls
    public func resume() {
        // AVAssetDownloadTask provides the ability to resume previously stopped downloads under certain circumstances. To do so, simply instantiate a new AVAssetDownloadTask with an AVURLAsset instantiated with a file NSURL pointing to the partially downloaded bundle with the desired download options, and the download will continue restoring any previously downloaded data. FPS keys remain encrypted in persisted form during this process.
        guard let task = task else {
            restoreOrCreate(forceNew: true) { [weak self] in
                guard let `self` = self else { return }
                `self`.task?.resume()
                `self`.eventPublishTransmitter.onResumed(`self`)
            }
            return
        }
        task.resume()
        eventPublishTransmitter.onResumed(self)
    }
    
    public func suspend() {
        // If a download has been started, it can be stopped. AVAssetDownloadTask inherits from NSURLSessionTask, and downloads can be suspended or cancelled using the corresponding methods inherited from NSURLSessionTask. In the case where a download is stopped and there is no intention of resuming it, apps are responsible for deleting the portion of the asset already downloaded to a user’s device. The NSURLSessionTask documentation on developer.apple.com contains more details about this process.
        
        guard let task = self.task else { return }
        task.suspend()
        eventPublishTransmitter.onSuspended(self)
    }
    
    /// NOTE: Canceling a download in progress will trigger `assetDownloadTask:didFinishDownloadingTo`. That `URL` can be used to "resume" the download at a later time.
    public func cancel() {
        // Downloaded HLS assets can be deleted using [NSFileManager removeItemAtURL:] with the URL for the downloaded version of the asset. In addition, if a user deletes the app that downloaded the HLS assets, they will also delete all content that the app stored to disk.
        
        guard let task = self.task else { return }
        task.cancel()
        
        // NOTE: `onCanceled` called once `didCompleteWithError` delegate methods is triggered
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
    public typealias DownloadEventError = DownloadError
}
