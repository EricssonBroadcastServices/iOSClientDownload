//
//  SessionManager.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public class SessionManager {
    public static let defaultSessionConfigurationIdentifier = "com.emp.download.session.background"
    internal static let defaultSessionConfiguration = URLSessionConfiguration.background(withIdentifier: defaultSessionConfigurationIdentifier)
    public static let `default` = SessionManager()
    
    /// The underlying session.
    internal let session: AVAssetDownloadURLSession
    
    /// The session delegate handling all the task and session delegate callbacks.
    internal let delegate: SessionDelegate
    
    
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
        configuration: URLSessionConfiguration = SessionManager.defaultSessionConfiguration,
        delegate: SessionDelegate = SessionDelegate())
    {
        self.delegate = delegate
        self.session = AVAssetDownloadURLSession(configuration: configuration,
                                                 assetDownloadDelegate: delegate,
                                                 delegateQueue: OperationQueue.main)
        session.configuration.identifier
        
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

extension SessionManager {
    @available(iOS 10.0, *)
    public func download(mediaLocator: URL, assetId: String, artwork artworkData: Data? = nil, using fairplayRequester: DownloadFairplayRequester? = nil) -> DownloadTask {
        let configuration = DownloadTask.Configuration(url: mediaLocator,
                                                       assetId: assetId,
                                                       artwork: artworkData,
                                                       destination: nil)
        
        if let currentTask = delegate[assetId] {
            return currentTask
        }
        else {
            return DownloadTask(sessionManager: self, configuration: configuration, fairplayRequester: fairplayRequester)
        }
    }
    
    @available(iOS, introduced: 9.0, deprecated: 10.0)
    public func download(mediaLocator: URL, assetId: String, to destination: URL, using fairplayRequester: DownloadFairplayRequester? = nil) -> DownloadTask {
        let configuration = DownloadTask.Configuration(url: mediaLocator,
                                                       assetId: assetId,
                                                       artwork: nil,
                                                       destination: destination)
        
        if let currentTask = delegate[assetId] {
            return currentTask
        }
        else {
            return DownloadTask(sessionManager: self, configuration: configuration, fairplayRequester: fairplayRequester)
        }
    }
    
    internal func task(assetId: String, callback: @escaping (AVAssetDownloadTask?) -> Void) {
        self.session
            .getAllTasks{ tasks in
                tasks.forEach{ print("📌 \($0.taskDescription)") }
                let task = tasks
                    .flatMap{ $0 as? AVAssetDownloadTask }
                    .filter{ $0.taskDescription == assetId } // TODO: .filter{ $0.taskDescription == configuration.assetId && $0.urlAsset.url == configuration.url } ?
                    .first
                callback(task)
                return
        }
    }
}
