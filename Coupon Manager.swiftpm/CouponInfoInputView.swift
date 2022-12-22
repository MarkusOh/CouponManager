import SwiftUI

struct CouponInfoInputView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var couponCode: String
    @Binding var barcodeType: BarcodeType
    
    @State var couponName: String = ""
    @State var couponBalance: Double = 0.0
    @State var couponExpirationDate: Date = .now
    
    let inputCompletionHandler: (Coupon) -> Void
    
    var body: some View {
        NavigationView(content: {
            Form(content: {
                Section("쿠폰 이름", content: {
                    TextField("맥도날드 기프티콘", text: $couponName)
                })
                
                Section("쿠폰 코드", content: {
                    Text(couponCode)
                })
                
                Section("쿠폰 잔액", content: {
                    TextField("1,0000원", value: $couponBalance, format: .currency(code: "KRW"))
                        .keyboardType(.numberPad)
                })
                
                Section("쿠폰 유효 기간", content: {
                    DatePicker("쿠폰 유효 기간", selection: $couponExpirationDate, displayedComponents: .date)
                        .labelsHidden()
                })
                
                Button("입력 완료", action: {
                    inputCompletionHandler(Coupon(name: couponName, code: couponCode, balance: couponBalance, expirationDate: couponExpirationDate, barcodeType: barcodeType))
                    dismiss()
                })
            })
        })
        .navigationViewStyle(.stack)
    }
}
