import SwiftUI

struct CouponView: View {
    let coupon: Coupon
    let balanceSetterHandler: (Double) -> Void
    
    @State private var howMuchSpent = 0.0
    @State private var isMoneyEditViewOpen = false
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text(coupon.name)
                        .font(.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .foregroundColor(.black.opacity(0.8))
                    Spacer()
                }
                HStack {
                    Text("\(coupon.expirationDate.formatted(date: .numeric, time: .omitted)) 만료")
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .foregroundColor(.black.opacity(0.4))
                    Spacer()
                }
            }
            GeometryReader(content: { geometry in
                VStack {
                    if let barcodeImageView = BarcodeGenerator.barcodeImageViewGenerate(with: coupon) {
                        barcodeImageView
                            .resizable()
                            .scaledToFit()
                            .frame(minWidth: geometry.size.width, minHeight: .zero)
                    }
                    Text(coupon.code)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            })
            HStack {
                Text("\(coupon.balance.formatted())원 남았습니다")
                Spacer()
                Button {
                    isMoneyEditViewOpen.toggle()
                } label: { 
                    Image(systemName: "wonsign.circle")
                        .resizable()
                        .foregroundColor(.accentColor)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 30)
                }
            }
            Spacer()
        }
        .moneyEditor(coupon: coupon, isPresented: $isMoneyEditViewOpen, balanceSetterHandler: balanceSetterHandler)
        .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 250)
    }
}

struct BarcodeView_Previews: PreviewProvider {
    static var previews: some View {
        CouponView(coupon: Coupon(name: "McDonalds", code: "Some code", balance: 4300, expirationDate: .now, barcodeType: .code128), balanceSetterHandler: { _ in })
    }
}
