//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/01/09.
//

import Foundation

struct NaverShopItem: Codable, Identifiable {
    var id: String {
        productId
    }
    
    var title: String         // Product title
    let link: String          // Link to the product
    let image: String         // Thumbnail image of the product
    let lprice: Int           // lowest price
    let hprice: Int           // highest price
    let mallName: String      // Shoping mall name
    let productId: String     // Product ID for Naver Shopping
    let productType: Int?
    let brand: String
    let maker: String
    let category1: String     // Product Categroy (Major Classification)
    let category2: String     // Product Category (Mid Classification)
    let category3: String     // Product Category (Minor Classification)
    let category4: String     // Product Category (Detailed Cassification)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.link = try container.decode(String.self, forKey: .link)
        self.image = try container.decode(String.self, forKey: .image)
        self.lprice = Int((try? container.decode(String.self, forKey: .lprice)) ?? "0") ?? 0
        self.hprice = Int((try? container.decode(String.self, forKey: .hprice)) ?? "0") ?? 0
        self.mallName = try container.decode(String.self, forKey: .mallName)
        self.productId = try container.decode(String.self, forKey: .productId)
        self.productType = try? container.decode(Int.self, forKey: .productType)
        self.brand = try container.decode(String.self, forKey: .brand)
        self.maker = try container.decode(String.self, forKey: .maker)
        self.category1 = try container.decode(String.self, forKey: .category1)
        self.category2 = try container.decode(String.self, forKey: .category2)
        self.category3 = try container.decode(String.self, forKey: .category3)
        self.category4 = try container.decode(String.self, forKey: .category4)
    }
}

struct NaverShopSearchResult: Codable {
    let lastBuildDate: String // Searched time
    let total: Int            // Total searched items
    let start: Int            // Starting position of the search
    let display: Int          // Displayed number of items
    let items: [NaverShopItem]         // Searched items
}
