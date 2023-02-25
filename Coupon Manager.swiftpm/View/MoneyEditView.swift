//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/01/01.
//

import SwiftUI

struct MoneyEditView: View {
    var coupon: Coupon
    @Binding var isPresented: Bool
    let balanceSetterHandler: (Double) -> Void
    
    @State private var spentMoney: Double = 0.0
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack {
            ScrollView(content: {
                VStack(spacing: 0) {
                    HStack {
                        Text(coupon.name)
                            .font(.title2)
                            .bold()
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(.gray.opacity(0.25))
                    BarcodeGenerator.barcodeImageViewGenerate(with: coupon)?
                        .resizable()
                        .scaledToFit()
                    Text(coupon.code)
                        .padding(.bottom)
                    HStack {
                        Spacer()
                        Text("\(coupon.expirationDate.formatted(date: .numeric, time: .omitted)) 만료")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .bold()
                            .lineLimit(1)
                            .padding([.bottom, .trailing])
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                .shadow(radius: 8)
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack {
                Text("\(coupon.balance.formatted()) 원")
                    .font(.title2)
                    .padding(.leading)
                Spacer()
            }
            HStack {
                Text("⊝")
                    .font(.title2)
                    .foregroundColor(.red)
                    .bold()
                TextField("사용한 금액", value: $spentMoney, formatter: NumberFormatter.currencyFormatter)
                    .font(.title2)
                    .focused($isFocused)
                    .keyboardType(.numberPad)
            }
            .padding([.leading, .trailing, .bottom])
            HStack {
                Spacer()
                Button(action: {
                    balanceSetterHandler(coupon.balance - spentMoney)
                    isPresented.toggle()
                }, label: {
                    Text("반영")
                        .font(.title2)
                        .bold()
                })
            }
            .padding([.trailing, .bottom])
        }
        .onAppear {
            isFocused = true
        }
    }
}

struct MoneyEditor: ViewModifier {
    var coupon: Coupon
    @Binding var isPresented: Bool
    let balanceSetterHandler: (Double) -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, content: {
                MoneyEditView(coupon: coupon, isPresented: $isPresented, balanceSetterHandler: balanceSetterHandler)
            })
    }
}

extension View {
    func moneyEditor(coupon: Coupon, isPresented: Binding<Bool>, balanceSetterHandler: @escaping (Double) -> Void) -> some View {
        self.modifier(MoneyEditor(coupon: coupon, isPresented: isPresented, balanceSetterHandler: balanceSetterHandler))
    }
}

struct MoneyEditView_Previews: PreviewProvider {
    @State static var isPresented: Bool = true
    
    static var previews: some View {
        MoneyEditView(coupon: Coupon(name: "맥도날드 쿠폰", code: "439399284", balance: 30000, expirationDate: .distantFuture, barcodeType: .code128), isPresented: $isPresented, balanceSetterHandler: { _ in
            
        })
    }
}
