import SwiftUI

struct BarcodeView: View {
    let coupon: Coupon
    let balanceSetterHandler: (Double) -> Void
    
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
                    Text(coupon.code)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
            })
            HStack {
                Text("\(coupon.balance.formatted())원 남았습니다")
                Spacer()
                Button { 
                    isMoneyEditViewOpen.toggle()
                    
                    if !isMoneyEditViewOpen {
                        let newBalance = coupon.balance - howMuchSpent
                        isFocused = false
                        howMuchSpent = .zero
                        
                        balanceSetterHandler(newBalance)
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
        if coupon.barcodeType == "Barcode" {
            return BarcodeGenerator.generateBarcodeView(from: coupon.code)
        } else { // barcodeType == "QR Code"
            return BarcodeGenerator.generateQRCodeView(from: coupon.code)
        }
    }
}
