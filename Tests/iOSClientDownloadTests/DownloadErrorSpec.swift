//
//  DownloadErrorSpec.swift
//  DownloadTests
//
//  Created by Fredrik Sjöberg on 2017-11-14.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import iOSClientDownload

class DownloadErrorSpec: QuickSpec {
    override func spec() {
        describe("Basics") {
            it("Should produce correct error codes") {
                expect(TaskError.generalError(error: FakeError.fake).code).to(equal(101))
                expect(TaskError.failedToStartTaskWithoutDestination.code).to(equal(102))
                expect(TaskError.completedWithError(error: FakeError.fake).code).to(equal(103))
                expect(TaskError.completedWithoutValidStorageUrl.code).to(equal(104))
                expect(TaskError.noStoragePathOnCancel.code).to(equal(105))
                expect(TaskError.downloadSessionInvalidated.code).to(equal(106))
                expect(TaskError.storageUrlNotFound.code).to(equal(107))
                expect(TaskError.targetUrlNotFound.code).to(equal(108))
            }
        }
    }
    
    enum FakeError: Error {
        case fake
    }
}
