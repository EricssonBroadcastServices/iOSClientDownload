//
//  SessionManager.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation


public enum SessionConfigurationIdentifier: String {
    case `default` = "com.emp.download.session.background"
}


public class SessionManager<T: TaskType> {
    /// The underlying session.
    internal let session: AVAssetDownloadURLSession
    
    /// The session delegate handling all the task and session delegate callbacks.
    internal(set) public var delegate: SessionDelegate<T>
    
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
    public init(
        configuration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: SessionConfigurationIdentifier.default.rawValue),
        delegate: SessionDelegate<T> = SessionDelegate())
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
    
//    deinit {
//        session.finishTasksAndInvalidate()
//    }
    
    
    //    @discardableResult
    //    public func allow(cellularAccess: Bool) -> Self {
    //        sessionConfiguration.allowsCellularAccess = cellularAccess
    //        return self
    //    }
}

extension SessionManager where T == Task {
    @available(iOS 10.0, *)
    public func download(mediaLocator: URL, assetId: String, artwork artworkData: Data? = nil, using fairplayRequester: FairplayRequester? = nil, analyticsProvider: TaskAnalyticsProvider? = nil) -> T {
        let configuration = Configuration(identifier: assetId,
                                          url: mediaLocator,
                                          artwork: artworkData)
        
        if let currentTask = delegate[assetId] {
            print("♻️ Retrieved DownloadTask associated with request for: \(assetId)")
            return currentTask
        }
        else {
            print("✅ Created new DownloadTask for: \(assetId)")
            return Task(sessionManager: self,
                        configuration: configuration,
                        fairplayRequester: fairplayRequester,
                        analyticsProvider: analyticsProvider)
        }
    }
    
    @available(iOS, introduced: 9.0, deprecated: 10.0)
    public func download(mediaLocator: URL, assetId: String, to destination: URL, using fairplayRequester: FairplayRequester? = nil, analyticsProvider: TaskAnalyticsProvider? = nil) -> T {
        let configuration = Configuration(identifier: assetId,
                                          url: mediaLocator,
                                          artwork: nil)
        let responseData = ResponseData(destination: destination)
        if let currentTask = delegate[assetId] {
            print("♻️ Retrieved DownloadTask associated with request for: \(assetId)")
            return currentTask
        }
        else {
            print("✅ Created new DownloadTask for: \(assetId)")
            return Task(sessionManager: self,
                        configuration: configuration,
                        fairplayRequester: fairplayRequester,
                        analyticsProvider: analyticsProvider,
                        responseData: responseData)
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
                self?.printRelovedState(for: assetTask)
                callback(assetTask)
        }
    }
    
    public func restoreTasks(callback: @escaping ([AVAssetDownloadTask]) -> Void) {
        print("🛏 Restoring DownloadTasks...")
        session
            .getAllTasks{ [weak self] tasks in
                let downloadTasks = tasks
                    .compactMap{ task -> AVAssetDownloadTask? in
                        guard let assetTask = task as? AVAssetDownloadTask else {
                            print("❌ Ignoring \(task.taskDescription). Task is not an AVAssetDownloadTask. ")
                            return nil
                        }
                        
                        guard let assetId = assetTask.taskDescription else {
                            print("❌ Ignoring AVAssetDownloadTask without a unique assetId.")
                            return nil
                        }
                        
                        print("♻️ Found AVAssetDownloadTask \(assetId)",assetTask.urlAsset.url)
                        
                        self?.printRelovedState(for: assetTask)
                        return assetTask
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
