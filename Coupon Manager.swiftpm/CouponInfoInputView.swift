import SwiftUI

struct CouponInfoInputView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var couponCode: String
    @Binding var couponBalance: Double
    @Binding var couponExpirationDate: Date
    
    var body: some View {
        NavigationView(content: {
            Form(content: {
                Section(content: {
                    Text("쿠폰 코드: \(couponCode)")
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
                    dismiss()
                })
            })
        })
        .navigationViewStyle(.stack)
    }
}
