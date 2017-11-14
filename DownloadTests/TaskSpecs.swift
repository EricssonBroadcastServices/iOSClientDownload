//
//  TaskSpecs.swift
//  DownloadTests
//
//  Created by Fredrik Sjöberg on 2017-11-14.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import Download

class TaskSpec: QuickSpec {
    override func spec() {
        describe("Basics") {
            let sessionManager = SessionManager<Task>()
            let url = URL(fileURLWithPath: "http://www.example.com")
            let assetId = UUID().uuidString
            let provider = TestAnalyticsProvider()
            if #available(iOS 10.0, *) {
                let task = sessionManager.download(mediaLocator: url, assetId: assetId, analyticsProvider: provider)
                it("Should prepare valid configuration") {
                    expect(task.configuration.artwork).to(beNil())
                    expect(task.configuration.identifier).to(equal(assetId))
                    expect(task.configuration.url).toNot(beNil())
                    expect(task.configuration.url).to(equal(url))
                }
                
                it("Should not have ResponseData") {
                    expect(task.responseData.destination).to(beNil())
                    expect(task.responseData.resolvedMediaSelection).to(beNil())
                }
                
                it("Should record bitrate selection") {
                    task.use(bitrate: 10)
                    expect(task.configuration.requiredBitrate).to(equal(10))
                }
                
                it("Should start in .notStated State") {
                    expect(task.state).to(equal(Task.State.notStarted))
                }
                
                it("Should have AnalyticsProvider attached") {
                    expect(task.analyticsConnector.provider).toNot(beNil())
                    
                    task.analyticsConnector.onDownloadError(task,DownloadError.noStoragePathOnCancel)
                    task.analyticsConnector.onDownloadCancelled(task)
                    task.analyticsConnector.onDownloadCompleted(task)
                    task.analyticsConnector.onDownloadPaused(task)
                    task.analyticsConnector.onDownloadStarted(task)
                    task.analyticsConnector.onDownloadResumed(task)
                    task.analyticsConnector.onDownloadStopped(task)
                    
                    expect(provider.testError).toNot(beNil())
                    expect(provider.cancelled).to(beTrue())
                    expect(provider.completed).to(beTrue())
                    expect(provider.paused).to(beTrue())
                    expect(provider.started).to(beTrue())
                    expect(provider.resumed).to(beTrue())
                    expect(provider.stopped).to(beTrue())
                }
                
                it("Should NOT respond to cancel unless prepared") {
                    expect(task.task).to(beNil())
                    var onCanceled = false
                    task.onCanceled { _ in
                        onCanceled = true
                    }.cancel()
                    
                    expect(onCanceled).toEventually(equal(false))
                }
                
                it("Should NOT respond to suspend unless prepared") {
                    expect(task.task).to(beNil())
                    var onSuspended = false
                    task.onSuspended { _ in
                        onSuspended = true
                        }.suspend()
                    
                    expect(onSuspended).toEventually(equal(false))
                }
                
                it("Should have NO urlAsset unless prepared") {
                    expect(task.urlAsset).to(beNil())
                }
                
                it("Should fail with invalid URL") {
                    var onPrepared: Bool = false
                    var onResumed: Bool = false
                    var responseError: DownloadError? = nil
                    task
                        .onPrepared{ task in
                            onPrepared = true
                        }
                        .onResumed{ task in
                            onResumed = true
                        }
                        .onError{ task, url, error in
                        responseError = error
                        }
                        .prepare()
                        .resume()
                    
                    expect(onPrepared).toEventually(beTrue())
                    expect(onResumed).toEventually(beTrue())
                    expect(responseError).toEventuallyNot(beNil())
                }
            }
        }
    }
}

class TestAnalyticsProvider: TaskAnalyticsProvider {
    var testError: DownloadError?
    var cancelled: Bool = false
    var completed: Bool = false
    var paused: Bool = false
    var started: Bool = false
    var resumed: Bool = false
    var stopped: Bool = false
    
    public init() { }
    func bind(connector: TaskAnalyticsConnector) {
        connector.downloadCancelledEvent{ task in
            self.cancelled = true
        }
        
        connector.downloadCompletedEvent{ task in
            self.completed = true
        }
        
        connector.downloadErrorEvent{ task, error in
            self.testError = error
        }
        
        connector.downloadPausedEvent{ task in
            self.paused = true
        }
        
        connector.downloadStartedEvent{ task in
            self.started = true
        }
        
        connector.downloadResumedEvent{ task in
            self.resumed = true
        }
        
        connector.downloadStoppedEvent{ task in
            self.stopped = true
        }
    }
}
