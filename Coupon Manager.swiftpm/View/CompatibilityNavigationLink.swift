//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/02/26.
//

import SwiftUI

struct CompatibilityNavigationLink<MainBody: View, DestinationBody: View>: View {
    @ViewBuilder var mainBody: () -> MainBody
    @ViewBuilder var destination: () -> DestinationBody
    @Binding var isPresented: Bool
    
    var body: some View {
        if #available(iOS 16.0, *) {
            mainBody()
                .navigationDestination(isPresented: $isPresented, destination: destination)
        } else {
            ZStack {
                mainBody()
                NavigationLink("Hidden Link", destination: destination(), isActive: $isPresented)
                    .hidden()
            }
        }
    }
}
