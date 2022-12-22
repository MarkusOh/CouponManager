import SwiftUI

struct BarcodeView: View {
    let couponCode: String
    let barcodeType: String
    @Binding var moneyLeft: Double
    @State private var howMuchSpent = 0.0
    @State private var isMoneyEditViewOpen = false
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack {
            GeometryReader(content: { geometry in
                VStack {
                    if let barcodeImageView = barcodeImageViewGenerate() {
                        barcodeImageView
                            .resizable()
                            .scaledToFit()
                            .frame(minWidth: geometry.size.width, minHeight: .zero)
                    }
                    Text(couponCode)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
            })
            HStack {
                Text("\(moneyLeft.formatted())원 남았습니다")
                Spacer()
                Button { 
                    isMoneyEditViewOpen.toggle()
                    
                    if !isMoneyEditViewOpen {
                        isFocused = false
                        moneyLeft -= howMuchSpent
                        howMuchSpent = .zero
                        CouponDataProvider.shared.saveCoupons()
                    }
                } label: { 
                    Image(systemName: isMoneyEditViewOpen ? "minus.circle" : "wonsign.circle")
                        .foregroundColor(.accentColor)
                        .aspectRatio(1, contentMode: .fill)
                }
            }
            
            if isMoneyEditViewOpen {
                TextField("사용한 금액", value: $howMuchSpent, format: .currency(code: "KRW"))
                    .keyboardType(.numberPad)
            }
        }
        .frame(width: 300, height: 250)
    }
    
    func barcodeImageViewGenerate() -> Image? {
        print(barcodeType)
        
        if barcodeType == "Barcode" {
            return BarcodeGenerator.generateBarcodeView(from: couponCode)
        } else { // barcodeType == "QR Code"
            return BarcodeGenerator.generateQRCodeView(from: couponCode)
        }
    }
}
