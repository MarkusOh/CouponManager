//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/26.
//

import Foundation

struct GooglePhotosAlbumsStructure: Codable {
    let albums: [GooglePhotosAlbum]
}

struct GooglePhotosAlbum: Identifiable, Codable {
    var id: String
    let title: String
    let productUrl: URL
    let mediaItemsCount: Int
    let coverPhotoBaseUrl: URL
    let coverPhotoMediaItemId: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.productUrl = URL(string: try container.decode(String.self, forKey: .productUrl))!
        self.mediaItemsCount = Int(try container.decode(String.self, forKey: .mediaItemsCount))!
        self.coverPhotoBaseUrl = URL(string: try container.decode(String.self, forKey: .coverPhotoBaseUrl))!
        self.coverPhotoMediaItemId = try container.decode(String.self, forKey: .coverPhotoMediaItemId)
    }
}

struct GooglePhotosStructure: Codable {
    let mediaItems: [GooglePhotoItem]
    let nextPageToken: String
}

struct GooglePhotoItem: Identifiable, Codable {
    var id: String
    let baseUrl: URL // <#Base_URL#>=w1000-h1000 => Give me an image lower than 1000x1000
    let mimeType: String
    let filename: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.baseUrl = URL(string: try container.decode(String.self, forKey: .baseUrl))!
        self.mimeType = try container.decode(String.self, forKey: .mimeType)
        self.filename = try container.decode(String.self, forKey: .filename)
    }
}
