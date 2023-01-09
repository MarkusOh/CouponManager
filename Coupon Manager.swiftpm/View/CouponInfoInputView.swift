import SwiftUI
import Combine

struct CouponInfoInputView: View {
    let dataProvider = CouponDataProvider.shared
    @Environment(\.dismiss) var dismiss
    
    var couponCode: String
    var barcodeType: BarcodeType
    
    @State var couponName: String = ""
    @State var couponBalance: Double = 0.0
    @State var couponExpirationDate: Date = .now
    
    var body: some View {
        Form {
            Section("쿠폰 이름", content: {
                TextField("맥도날드 기프티콘", text: $couponName)
            })
            
            Section("쿠폰 코드", content: {
                Text(couponCode)
            })
            
            Section("쿠폰 잔액", content: {
                TextField("￦10000", value: $couponBalance, formatter: NumberFormatter.currencyFormatter)
                    .keyboardType(.numberPad)
            })
            
            Section("쿠폰 유효 기간", content: {
                DatePicker("쿠폰 유효 기간", selection: $couponExpirationDate, displayedComponents: .date)
                    .labelsHidden()
            })
            
            Button("입력 완료", action: {
                dataProvider.create(coupon: Coupon(name: couponName, code: couponCode, balance: couponBalance, expirationDate: couponExpirationDate, barcodeType: barcodeType))
                dismiss()
            })
        }
        .navigationTitle("쿠폰입력")
    }
}
