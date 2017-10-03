//
//  LocalMediaLog.swift
//  Download
//
//  Created by Fredrik Sjöberg on 2017-10-03.
//  Copyright © 2017 emp. All rights reserved.
//

import Foundation

internal struct LocalMediaLog: Codable {
    /// List of local assets
    let log: [LocalMediaRecord]
}

internal struct LocalMediaRecord: Codable {
    // URL encoded as bookmark data
    let urlBookmark: Data
    
    /// Id for the asset at `bookmarkURL`
    let assetId: String
}
