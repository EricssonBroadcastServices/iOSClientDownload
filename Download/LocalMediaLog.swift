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
    /// URL encoded as bookmark data
    var urlBookmark: Data? {
        switch downloadState {
        case .completed(urlBookmark: let data): return data
        case .inProgress: return nil
        }
    }
    
    /// State
    let downloadState: DownloadState
    
    /// Id for the asset at `bookmarkURL`
    let assetId: String
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        assetId = try container.decode(String.self, forKey: .assetId)
        
        if let data = try container.decodeIfPresent(Data.self, forKey: .downloadState) {
            downloadState = .completed(urlBookmark: data)
        }
        else {
            downloadState = .inProgress
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(assetId, forKey: .assetId)
        
        switch downloadState {
        case .completed(urlBookmark: let data): try container.encode(data, forKey: .downloadState)
        default: return
        }
    }
    
    internal init(assetId: String, completedAt location: URL?) throws {
        self.assetId = assetId
        if let data = try location?.bookmarkData() {
            downloadState = .completed(urlBookmark: data)
        }
        else {
            downloadState = .inProgress
        }
    }
    
    internal enum DownloadState {
        
        /// URL encoded as bookmark data
        case completed(urlBookmark: Data)
        
        /// No destination might have been set
        case inProgress
    }
    
    internal enum CodingKeys: String, CodingKey {
        case downloadState
        case assetId
    }
}
