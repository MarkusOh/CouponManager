//
//  SwiftUIView.swift
//  
//
//  Created by Seungsub Oh on 2023/01/02.
//

import SwiftUI
import Foundation

struct SnackBarView: View {
    let title: String?
    let message: String?
    
    @Binding var isPresented: Bool
    @State private var snackBarPositionOffset: Double = 0
    
    var body: some View {
        if isPresented {
            GeometryReader { geo in
                VStack {
                    Spacer()
                        .frame(height: geo.size.height - snackBarPositionOffset)
                        .task { @MainActor in
                            withAnimation(.spring(blendDuration: 0.5)) {
                                snackBarPositionOffset = 150
                            }
                            
                            try! await Task.sleep(nanoseconds: 3_000_000_000)
                            
                            withAnimation(.spring(blendDuration: 0.5)) {
                                snackBarPositionOffset = 0
                            }
                            
                            try! await Task.sleep(nanoseconds: 500_000_000)
                            
                            isPresented = false
                        }
                    
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
                            
                            if let message = message {
                                HStack {
                                    Text(message)
                                        .font(.body)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.all, 10)
                        .background(Color.accentColor.opacity(0.5))
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                        .padding()
                        .shadow(radius: 15)
                    }
                    .opacity(snackBarPositionOffset / 150)
                }
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SnackBarView(title: "Hey ho", message: "Oh good it's you", isPresented: .constant(true))
    }
}
