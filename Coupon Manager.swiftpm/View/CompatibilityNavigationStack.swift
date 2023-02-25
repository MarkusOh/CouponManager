//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/02/26.
//

import SwiftUI

struct CompatibilityNavigationStack<MainBody: View>: View {
    @ViewBuilder var mainBody: () -> MainBody
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                mainBody()
            }
        } else {
            NavigationView {
                mainBody()
            }.navigationViewStyle(.stack)
        }
    }
}

struct CompatibilityNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        CompatibilityNavigationStack {
            Text("Oh Hello")
        }
    }
}
