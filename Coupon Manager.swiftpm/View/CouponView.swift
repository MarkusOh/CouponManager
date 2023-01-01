import SwiftUI

struct CouponView: View {
    let coupon: Coupon
    let balanceSetterHandler: (Double) -> Void
    
    @State private var howMuchSpent = 0.0
    @State private var isMoneyEditViewOpen = false {
        didSet {
            guard oldValue == true && isMoneyEditViewOpen == false else { return }
            
            // SwiftUI does not allow changing the value when the textfield is focused
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                howMuchSpent = .zero
            }
        }
    }
    @FocusState var isFocused: Bool
    
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
                    if let barcodeImageView = barcodeImageViewGenerate() {
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
                    if isMoneyEditViewOpen {
                        let newBalance = coupon.balance - howMuchSpent
                        isFocused = false
                        
                        balanceSetterHandler(newBalance)
                    }
                    
                    isMoneyEditViewOpen.toggle()
                } label: { 
                    Image(systemName: isMoneyEditViewOpen ? "minus.circle" : "wonsign.circle")
                        .resizable()
                        .foregroundColor(.accentColor)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 30)
                }
            }
            
            if isMoneyEditViewOpen {
                TextField("사용한 금액", value: $howMuchSpent, formatter: NumberFormatter.currencyFormatter)
                    .focused($isFocused)
                    .keyboardType(.numberPad)
                    .onAppear {
                        isFocused.toggle()
                    }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 250)
    }
    
    func barcodeImageViewGenerate() -> Image? {
        if coupon.barcodeType == .code128 {
            return BarcodeGenerator.generateBarcodeView(from: coupon.code)
        } else { // barcodeType == "QR Code"
            return BarcodeGenerator.generateQRCodeView(from: coupon.code)
        }
    }
}

struct BarcodeView_Previews: PreviewProvider {
    static var previews: some View {
        CouponView(coupon: Coupon(name: "McDonalds", code: "Some code", balance: 4300, expirationDate: .now, barcodeType: .code128), balanceSetterHandler: { _ in })
    }
}
