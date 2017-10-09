//
//  SessionDelegate.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-09-30.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation
import AVFoundation

public class SessionDelegate: NSObject {
    
    /// Overrides default behavior for URLSessionDelegate method `urlSessionDidFinishEvents(forBackgroundURLSession:)`.
    internal var sessionDidFinishEventsForBackgroundURLSession: ((URLSession) -> Void)?
    
    private var requests: [Int: DownloadTask] = [:]
    private let lock = NSLock()
    
    /// Access the task delegate for the specified asset identifier in a thread-safe manner.
    internal subscript(identifier: String) -> DownloadTask? {
        get {
            lock.lock() ; defer { lock.unlock() }
            requests.forEach{ print("📍 Active DownloadTask \($0.value.configuration.assetId)") }
            return requests.filter{ $0.value.configuration.assetId == identifier }.first?.value
        }
    }
    
    /// Access the task delegate for the specified task in a thread-safe manner.
    internal subscript(task: AVAssetDownloadTask) -> DownloadTask? {
        get {
            lock.lock() ; defer { lock.unlock() }
            return requests[task.taskIdentifier]
        }
        set {
            lock.lock() ; defer { lock.unlock() }
            requests[task.taskIdentifier] = newValue
        }
    }
    
    // MARK: Lifecycle
    
    /// Initializes the `SessionDelegate` instance.
    ///
    /// - returns: The new `SessionDelegate` instance.
    public override init() {
        super.init()
    }
}

extension SessionDelegate: AVAssetDownloadDelegate {
    
    /// NOTE: Will also be called when a partially downloaded asset is cancelled by the user
    /// Also called onError?
    ///
    /// This delegate callback should only be used to save the location URL somewhere in your application. Any additional work should be done in `URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:)`.
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        if let delegate = self[assetDownloadTask]?.delegate {
            delegate.urlSession(session, assetDownloadTask: assetDownloadTask, didFinishDownloadingTo: location)
        }
    }
    
    @available(iOS 9.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        if let delegate = self[assetDownloadTask]?.delegate {
            delegate.urlSession(session, assetDownloadTask: assetDownloadTask, didLoad: timeRange, totalTimeRangesLoaded: loadedTimeRanges, timeRangeExpectedToLoad: timeRangeExpectedToLoad)
        }
    }
    
    @available(iOS 9.0, *)
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        if let delegate = self[assetDownloadTask]?.delegate {
            delegate.urlSession(session, assetDownloadTask: assetDownloadTask, didResolve: resolvedMediaSelection)
        }
    }
}

extension SessionDelegate: URLSessionTaskDelegate {
    @available(iOS 11.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Swift.Void) {
        
    }
    
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Swift.Void) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Swift.Void) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
    }
    
    @available(iOS 10.0, *)
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let assetDownloadTask = task as? AVAssetDownloadTask else {
            // TODO: Is it wise to simply return? By design, only `AVAssetDownloadTask`s are supposed to be used here
            return
        }
        
        if let delegate = self[assetDownloadTask]?.delegate {
            delegate.urlSession(session, task: task, didCompleteWithError: error)
            
            self[assetDownloadTask] = nil
        }
    }
}

extension SessionDelegate: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("🚨 URLSession invalidated: \(error?.localizedDescription)")
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("🛏 URLSession finished background events")
        session.getAllTasks{ tasks in
            tasks.forEach{
                let task = $0 as! AVAssetDownloadTask
                print("📌 \(task.taskDescription) - \(task.urlAsset.url)")
                
            }
        }
    }
}
