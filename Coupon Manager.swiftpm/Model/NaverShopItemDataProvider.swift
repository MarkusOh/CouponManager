//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/01/09.
//

import Foundation
import Combine

class NaverShopItemDataProvider: ObservableObject {
    static let shared = NaverShopItemDataProvider()
    
    @Published var availableItems: [String: [NaverShopItem]] = [:]
    
    var subscriptions = Set<AnyCancellable>()
    
    func fetchItems(for name: String) {
        guard !Array(availableItems.keys).contains(name) else {
            return
        }
        
        fetchItemsFromNaver(for: name)
    }
    
    // Requests must include the name "잔액관리형", "디지털상품권", "금액권", "만원권" and merge the items by productId
    enum Keywords: String {
        case balanceManaged = "잔액관리형"
        case giftCertificate = "디지털상품권"
        case money = "금액권"
        case perTenDollar = "만원권"
    }
    
    func createURLComponentsForNaver(for name: String, with keyword: Keywords, at startPosition: Int = 1) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "openapi.naver.com"
        components.path = "/v1/search/shop.json"
        
        components.queryItems = [
            URLQueryItem(name: "query", value: "\(name) \(keyword.rawValue)"),
            URLQueryItem(name: "display", value: "20"),
            URLQueryItem(name: "start", value: "\(startPosition)"),
            URLQueryItem(name: "filter", value: "naverpay"),
            URLQueryItem(name: "exclude", value: "used:rental:cbshop")
        ]
        
        return components
    }
    
    func fetchItemsFromNaver(for name: String, at startPosition: Int = 1) {
        let keywords: [Keywords] = [.balanceManaged, .giftCertificate, .money, .perTenDollar]
        let componentsBasedOnKeywords = keywords.map({ createURLComponentsForNaver(for: name, with: $0, at: startPosition) })
        let requests = componentsBasedOnKeywords.map({ components in
            var request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            request.httpMethod = "GET"
            request.addValue("30nfB2mWH90lVPQFa0Gm", forHTTPHeaderField: "X-Naver-Client-Id")
            request.addValue("FanMUqP1lY", forHTTPHeaderField: "X-Naver-Client-Secret")
            return request
        })
        
        let decoder = JSONDecoder()
        var productIdsForFiltering: Set<String> = Set()
        
        let searchedCoupons: AnyPublisher<[NaverShopItem], Never> = requests.publisher.flatMap({ request -> AnyPublisher<(Data, HTTPURLResponse), Error> in
            return URLSession(configuration: .default).dataTaskPublisher(for: request)
        }).map(\.0).decode(type: NaverShopSearchResult.self, decoder: decoder).flatMap({ $0.items.publisher }).collect().flatMap { items in
            items.publisher
        }.filter { item in
            if productIdsForFiltering.contains(item.productId) {
                return false
            } else {
                productIdsForFiltering.insert(item.productId)
                return true
            }
        }.collect().replaceError(with: []).map { items in
            items.sorted { $0.lprice < $1.lprice }
        }.eraseToAnyPublisher()
        
        searchedCoupons
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] items in
                self.availableItems[name] = items
            }
            .store(in: &subscriptions)
    }
}

enum URLSessionError: Error {
    case dataUnavailable
    case failure(statusCode: Int)
    case responseIsNotHTTPURLResponse
}

extension URLSession {
    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), Error> {
        Future<(Data, HTTPURLResponse), Error> { promise in
            URLSession(configuration: .default)
                .dataTask(with: request) { data, response, error in
                    guard error == nil else {
                        promise(Result.failure(error!))
                        return
                    }
                    
                    guard let data = data else {
                        promise(Result.failure(URLSessionError.dataUnavailable))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        promise(Result.failure(URLSessionError.responseIsNotHTTPURLResponse))
                        return
                    }
                    
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        promise(Result.failure(URLSessionError.failure(statusCode: httpResponse.statusCode)))
                        return
                    }
                    
                    promise(Result.success((data, httpResponse)))
                }
                .resume()
        }
        .eraseToAnyPublisher()
    }
}
