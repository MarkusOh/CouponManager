import SwiftUI
import Combine

struct CouponShopView: View {
    @StateObject private var dataProvider = NaverShopItemDataProvider.shared
    
    @State private var selectedBrand = 0
    static let availableBrands = [ "BaskinRobbins": "배스킨라빈스",
                                   "Daiso": "다이소",
                                   "EdiyaCoffee": "이디야커피",
                                   "MammothCoffee": "매머드커피",
                                   "McDonalds": "맥도날드",
                                   "MegaCoffee": "메가커피",
                                   "OutbackSteakhouse": "아웃백",
                                   "Starbucks": "스타벅스",
                                   "Vips": "빕스" ]
    
    var availableBrandsKeys: [String] = CouponShopView.availableBrands.keys.map({ $0 }).sorted()
    
    var selectedBrandName: String {
        CouponShopView.availableBrands[availableBrandsKeys[selectedBrand]]!
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(zip(availableBrandsKeys.indices, availableBrandsKeys)), id: \.1) { (idx, brandName) in
                            VStack {
                                Image(brandName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .background(.white)
                                    .clipShape(Circle())
                                    .overlay {
                                        ZStack {
                                            Circle()
                                                .strokeBorder()
                                                .foregroundColor(.gray.opacity(0.3))
                                            if idx == selectedBrand {
                                                Circle()
                                                    .foregroundColor(.gray.opacity(0.3))
                                                CheckMark()
                                                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                                                    .padding()
                                                    .foregroundColor(.black.opacity(0.5))
                                            }
                                        }
                                    }
                                Text(CouponShopView.availableBrands[brandName]!)
                                    .font(.caption)
                            }
                            .onTapGesture {
                                selectedBrand = idx
                                dataProvider.fetchItems(for: selectedBrandName)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
                
                List(dataProvider.availableItems[selectedBrandName] ?? []) { item in
                    Button(action: {
                        UIApplication.shared.open(URL(string: item.link)!)
                    }, label: {
                        HStack {
                            AsyncImage(url: URL(string: item.image), content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Rectangle())
                            }, placeholder: {
                                ProgressView()
                                    .frame(width: 70, height: 70)
                            })
                            VStack {
                                HStack {
                                    boldedText(from: item.title)
                                        .foregroundColor(Color(uiColor: .label))
                                        .font(.system(size: 15))
                                    Spacer()
                                }
                                .padding(.bottom, 2)
                                HStack {
                                    Image(systemName: "wonsign.circle")
                                    Text(String(item.lprice))
                                    Spacer()
                                }
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            }
                            .padding(.leading)
                        }
                    })
                }
            }
            .navigationTitle("쿠폰 구매처")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            dataProvider.fetchItemsFromNaver(for: selectedBrandName)
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
}

struct CheckMark: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX - (rect.midX - rect.minX) / 4, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}

struct CouponShop: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                CouponShopView()
            }
    }
}

extension View {
    func couponShop(isPresented: Binding<Bool>) -> some View {
        self.modifier(CouponShop(isPresented: isPresented))
    }
}

struct CouponShopView_Previews: PreviewProvider {
    static var previews: some View {
        CouponShopView()
    }
}
