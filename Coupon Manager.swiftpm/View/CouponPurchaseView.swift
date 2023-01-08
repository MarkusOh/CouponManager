import SwiftUI
import Combine

struct CouponPurchaseView: View {
    @State private var items = [Item]()
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0..<10, id: \.self) { _ in
                            Circle()
                                .frame(width: 60)
                        }
                    }
                    .padding(.horizontal)
                }
                List(items) { item in
                    boldedText(from: item.title)
                }
            }
            .navigationTitle("쿠폰 구매처")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await fetchItemsFromNaver(for: "맥도날드")
        }
    }
    
    func boldedText(from string: String) -> some View {
        Group {
            let components = string.components(separatedBy: "</b>")
            components.reduce(Text("")) { partialResult, component in
                let texts = component.components(separatedBy: "<b>")
                if texts.count == 2 {
                    return partialResult + Text(texts[0]) + Text(texts[1]).bold()
                } else if texts.count == 1 && component.contains("<b>") {
                    return partialResult + Text(texts[0]).bold()
                } else {
                    return partialResult + Text(texts[0])
                }
            }
        }
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
            URLQueryItem(name: "display", value: "10"),
            URLQueryItem(name: "start", value: "\(startPosition)"),
            URLQueryItem(name: "filter", value: "naverpay"),
            URLQueryItem(name: "exclude", value: "used:rental:cbshop")
        ]
        
        return components
    }
    
    func fetchItemsFromNaver(for name: String, at startPosition: Int = 1) async {
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
        
        let searchedCoupons: AnyPublisher<[Item], Never> = requests.publisher.flatMap({ request -> AnyPublisher<(Data, HTTPURLResponse), Error> in
            return URLSession(configuration: .default).dataTaskPublisher(for: request)
        }).map(\.0).decode(type: SearchResults.self, decoder: decoder).flatMap({ $0.items.publisher }).collect().flatMap { items in
            items.publisher
        }.filter { item in
            if productIdsForFiltering.contains(item.productId) {
                return false
            } else {
                productIdsForFiltering.insert(item.productId)
                return true
            }
        }.collect().replaceError(with: []).eraseToAnyPublisher()
            
        for await coupons in searchedCoupons.values {
            items = coupons
        }
    }
}

struct CouponPurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        CouponPurchaseView()
    }
}

struct Item: Codable, Identifiable {
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

struct SearchResults: Codable {
    let lastBuildDate: String // Searched time
    let total: Int            // Total searched items
    let start: Int            // Starting position of the search
    let display: Int          // Displayed number of items 
    let items: [Item]         // Searched items
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
