//
//  SwiftUIView.swift
//  
//
//  Created by Seungsub Oh on 2023/01/02.
//

import SwiftUI

struct SnackBarView: View {
    @Binding var isShowing: Bool
    var title: String? = nil
    var message: String
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                if let title = title {
                    HStack {
                        Text(title)
                            .font(.title2)
                        Spacer()
                    }
                }
                HStack {
                    Text(message)
                        .font(.body)
                    Spacer()
                }
            }
            .padding(.all, 10)
            .background(Color.accentColor.opacity(0.5))
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .shadow(radius: isShowing ? 15 : 0)
            .offset(y: isShowing ? 0 : 150)
            .animation(.spring(), value: isShowing)
            .padding()
            .onChange(of: isShowing) { showStatus in
                guard showStatus else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    isShowing.toggle()
                }
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    @State static var isShowing: Bool = true
    
    static var previews: some View {
        VStack {
            Button("Show and Hide", action: {
                isShowing.toggle()
            })
            SnackBarView(isShowing: $isShowing, title: "Hey ho", message: "Oh good it's you")
        }
    }
}
