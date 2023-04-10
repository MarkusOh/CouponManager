//
//  SwiftUIView.swift
//  
//
//  Created by Seungsub Oh on 2023/01/02.
//

import SwiftUI
import Foundation

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
            .padding()
            .shadow(radius: 15)
            .opacity(isShowing ? 1 : 0)
            .offset(y: isShowing ? 0 : 150)
            .animation(.spring(), value: isShowing)
            .onChange(of: isShowing) { showStatus in
                guard showStatus else { return }
                
                Task { @MainActor in
                    try await Task.sleep(nanoseconds: 3000000000)
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
