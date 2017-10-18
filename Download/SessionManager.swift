//
//  SessionManager.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public class Configuration {
    public let identifier: String
    public var url: URL?
    public let artwork: Data?
    
    internal(set) public var requiredBitrate: Int64?
    
    public init(identifier: String, url: URL? = nil, artwork: Data? = nil) {
        self.identifier = identifier
        self.url = url
        self.artwork = artwork
    }
}

public class Progression {
    /// location.bookmarkData()
    /// Bookmark data should be used when persisting this url to disk
    ///
    /// - important: destination URL will be handled diffrently on iOS 9 vs iOS 10. On the later version, storage url for local media is handled and assigned by the system. In iOS 9 this path is supplied by the user.
    internal(set) public var destination: URL?
    
    ///  During the initial asset download, the user’s default media selections—their primary audio and video tracks—are downloaded. If additional media selections such as subtitles, closed captions, or alternative audio tracks are found, the session delegate’s URLSession:assetDownloadTask:didResolveMediaSelection: method is called, indicating that additional media selections exist on the server. To download additional media selections, save a reference to this resolved AVMediaSelection object so you can create subsequent download tasks to be executed serially.
    internal(set) public var resolvedMediaSelection: AVMediaSelection?
    
    public init(destination: URL? = nil, resolvedMediaSelection: AVMediaSelection? = nil) {
        self.destination = destination
        self.resolvedMediaSelection = resolvedMediaSelection
    }
}

public protocol DownloadTaskType: class, DownloadEventPublisher, DownloadProcess {
    
    var configuration: Configuration { get }
    var progression: Progression { get }
    var sessionManager: SessionManager<Self> { get }
    var delegate: DownloadTaskDelegate<Self> { get }
    var fairplayRequester: DownloadFairplayRequester? { get }
    var task: AVAssetDownloadTask? { get }
}

extension DownloadTaskType {
    /// The lowest media bitrate greater than or equal to this value will be selected. If no suitable media bitrate is found, the highest media bitrate will be selected. If this option is not specified, the highest media bitrate will be selected for download by default.
    ///
    /// - parameter bitrate: The bitrate to select, in bps (bits per second)
    @discardableResult
    public func use(bitrate: Int64?) -> Self {
        configuration.requiredBitrate = bitrate
        return self
    }
}

extension DownloadTaskType {
//    public func createNewTask() {
//        print("✅ No AVAssetDownloadTask prepared, creating new for: \(configuration.identifier)")
//        // Create a fresh task
//        let options = configuration.requiredBitrate != nil ? [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: configuration.requiredBitrate!] : nil
//
//        configureTask(with: options, using: configuration) { urlTask, error in
//            if let error = error {
//                eventPublishTransmitter.onError(self, progression.destination, error)
//                return
//            }
//
//            if let urlTask = urlTask {
//                task = urlTask
//                sessionManager.delegate[urlTask] = self
//                print("👍 DownloadTask prepared")
//                eventPublishTransmitter.onPrepared(self)
//            }
//        }
//    }
    
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
            guard let destination = progression.destination else {
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

extension DownloadTaskType {
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
                eventPublishTransmitter.onError(self, progression.destination, .downloadError(reason: .completedWithError(error: error)))
            }
            else {
                // Handle completion
                if let destination = progression.destination {
                    eventPublishTransmitter.onCompleted(self, destination)
                }
                else {
                    eventPublishTransmitter.onError(self, progression.destination, .downloadError(reason: .completedWithoutValidStorageUrl))
                }
            }
        }
    }
}


public class SessionManager<Task: DownloadTaskType> {
    /// The underlying session.
    internal let session: AVAssetDownloadURLSession
    
    /// The session delegate handling all the task and session delegate callbacks.
    internal(set) public var delegate: SessionDelegate<Task>
    
    
    /// The background completion handler closure provided by the UIApplicationDelegate
    /// `application:handleEventsForBackgroundURLSession:completionHandler:` method. By setting the background
    /// completion handler, the SessionDelegate `sessionDidFinishEventsForBackgroundURLSession` closure implementation
    /// will automatically call the handler.
    ///
    /// If you need to handle your own events before the handler is called, then you need to override the
    /// SessionDelegate `sessionDidFinishEventsForBackgroundURLSession` and manually call the handler when finished.
    ///
    /// `nil` by default.
    public var backgroundCompletionHandler: (() -> Void)?
    
    // MARK: - Lifecycle
    
    /// Creates an instance with the specified `configuration`, `delegate` and `serverTrustPolicyManager`.
    ///
    /// - parameter configuration:            The configuration used to construct the managed session.
    ///                                       `URLSessionConfiguration.default` by default.
    /// - parameter delegate:                 The delegate used when initializing the session. `SessionDelegate()` by
    ///                                       default.
    /// - parameter serverTrustPolicyManager: The server trust policy manager to use for evaluating all server trust
    ///                                       challenges. `nil` by default.
    ///
    /// - returns: The new `SessionManager` instance.
    internal init(
        configuration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "com.emp.download.session.background"),
        delegate: SessionDelegate<Task> = SessionDelegate())
    {
        self.delegate = delegate
        self.session = AVAssetDownloadURLSession(configuration: configuration,
                                                 assetDownloadDelegate: delegate,
                                                 delegateQueue: OperationQueue.main)
        
        delegate.sessionDidFinishEventsForBackgroundURLSession = { [weak self] session in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async { strongSelf.backgroundCompletionHandler?() }
        }
    }
    
    deinit {
        session.finishTasksAndInvalidate()
    }
    
    
    //    @discardableResult
    //    public func allow(cellularAccess: Bool) -> Self {
    //        sessionConfiguration.allowsCellularAccess = cellularAccess
    //        return self
    //    }
}

extension SessionManager where Task == DownloadTask {
    @available(iOS 10.0, *)
    public func download(mediaLocator: URL, assetId: String, artwork artworkData: Data? = nil, using fairplayRequester: DownloadFairplayRequester? = nil) -> Task {
        let configuration = Configuration(identifier: assetId,
                                          url: mediaLocator,
                                          artwork: artworkData)
        
        if let currentTask = delegate[assetId] {
            print("♻️ Retrieved DownloadTask associated with request for: \(assetId)")
            return currentTask
        }
        else {
            print("✅ Created new DownloadTask for: \(assetId)")
            return DownloadTask(sessionManager: self, configuration: configuration, fairplayRequester: fairplayRequester)
        }
    }
    
    @available(iOS, introduced: 9.0, deprecated: 10.0)
    public func download(mediaLocator: URL, assetId: String, to destination: URL, using fairplayRequester: DownloadFairplayRequester? = nil) -> Task {
        let configuration = Configuration(identifier: assetId,
                                          url: mediaLocator,
                                          artwork: nil)
        let progression = Progression(destination: destination)
        if let currentTask = delegate[assetId] {
            print("♻️ Retrieved DownloadTask associated with request for: \(assetId)")
            return currentTask
        }
        else {
            print("✅ Created new DownloadTask for: \(assetId)")
            return DownloadTask(sessionManager: self, configuration: configuration, fairplayRequester: fairplayRequester, progression: progression)
        }
    }
}

extension SessionManager {
    public func restoreTask(with assetId: String, callback: @escaping (AVAssetDownloadTask?) -> Void) {
        print("🛏 Restoring DownloadTask for",assetId)
        session
            .getAllTasks{ [weak self] tasks in
                let someTask = tasks
                    .filter{ $0.taskDescription == assetId }
                    .first
                
                guard let task = someTask, let assetTask = task as? AVAssetDownloadTask else {
                    callback(nil)
                    return
                }
                
                print("♻️ Found AVAssetDownloadTask \(assetId)",assetTask.urlAsset.url)
                callback(assetTask)
//                weakSelf.printRelovedState(for: assetTask)
//
//                let configuration = DownloadTask.Configuration(url: assetTask.urlAsset.url,
//                                                               identifier: assetId,
//                                                               artwork: nil,
//                                                               destination: nil)
//                let requester = assigningRequesterFor()
//                let downloadTask = DownloadTask(restoredTask: assetTask,
//                                                sessionManager: weakSelf,
//                                                configuration: configuration,
//                                                fairplayRequester: requester)
//                callback(downloadTask)
        }
    }
    
    public func restoreTasks(callback: @escaping ([AVAssetDownloadTask]) -> Void) {
        print("🛏 Restoring DownloadTasks...")
        session
            .getAllTasks{ [weak self] tasks in
                let downloadTasks = tasks
                    .flatMap{ task -> AVAssetDownloadTask? in
                        guard let assetTask = task as? AVAssetDownloadTask else {
                            print("❌ Ignoring \(task.taskDescription). Task is not an AVAssetDownloadTask. ")
                            return nil
                        }
                        
                        guard let assetId = assetTask.taskDescription else {
                            print("❌ Ignoring AVAssetDownloadTask without a unique assetId.")
                            return nil
                        }
                        
                        
                        print("♻️ Found AVAssetDownloadTask \(assetId)",assetTask.urlAsset.url)
                        return assetTask
//                        weakSelf.printRelovedState(for: assetTask)
//
//                        let configuration = DownloadTask.Configuration(url: assetTask.urlAsset.url,
//                                                                       identifier: assetId,
//                                                                       artwork: nil,
//                                                                       destination: nil)
//                        let requester = assigningRequesterFor(assetId)
//                        return DownloadTask(restoredTask: assetTask,
//                                            sessionManager: weakSelf,
//                                            configuration: configuration,
//                                            fairplayRequester: requester)
                    }
                callback(downloadTasks)
        }
    }
    
    private func printRelovedState(for assetTask: AVAssetDownloadTask) {
        switch assetTask.state {
        case .canceling: print("canceling")
        case .running: print("running")
        case .suspended: print("suspended")
        case .completed: print("completed")
        }
        if let taskError = assetTask.error as? NSError {
            if let reason = taskError.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] as? Int {
                let code = taskError.code
                if reason == NSURLErrorCancelledReasonUserForceQuitApplication &&
                    code == NSURLErrorCancelled {
                    print("NSURLErrorCancelledReasonUserForceQuitApplication")
                }
            }
        }
    }
    
}
