//
//  SwiftUIView.swift
//  
//
//  Created by Seungsub Oh on 2023/01/02.
//

import SwiftUI
import Foundation

struct SnackBarView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                HStack {
                    Text(title)
                        .font(.title2)
                    Spacer()
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
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SnackBarView(title: "Hey ho", message: "Oh good it's you")
    }
}
