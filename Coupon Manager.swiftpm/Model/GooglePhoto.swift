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

//struct GooglePhotoItem: Identifiable, Codable {
//    var id
//}
