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

@testable import Download

class DownloadErrorSpec: QuickSpec {
    override func spec() {
        describe("Basics") {
            it("Should produce correct error codes") {
                expect(DownloadError.generalError(error: FakeError.fake).code).to(equal(101))
                expect(DownloadError.failedToStartTaskWithoutDestination.code).to(equal(102))
                expect(DownloadError.completedWithError(error: FakeError.fake).code).to(equal(103))
                expect(DownloadError.completedWithoutValidStorageUrl.code).to(equal(104))
                expect(DownloadError.noStoragePathOnCancel.code).to(equal(105))
                expect(DownloadError.downloadSessionInvalidated.code).to(equal(106))
                expect(DownloadError.storageUrlNotFound.code).to(equal(107))
                expect(DownloadError.targetUrlNotFound.code).to(equal(108))
            }
        }
    }
    
    enum FakeError: Error {
        case fake
    }
}
