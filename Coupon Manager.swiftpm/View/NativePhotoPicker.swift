//
//  SwiftUIView.swift
//  
//
//  Created by Seungsub Oh on 2023/01/02.
//

import SwiftUI
import PhotosUI

enum NativePhotoPickerError: Error {
    case dataUnavailable
    case imageUnavailable
}

struct NativePhotoPickerLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columns: Double
        if UIDevice.current.userInterfaceIdiom == .phone {
            columns = 3
        } else {
            columns = 5
        }
        
        for (index, subview) in subviews.enumerated() {
            let sideLength = bounds.size.width / columns
            
            let viewSize = subview.sizeThatFits(ProposedViewSize(width: sideLength, height: sideLength))
            subview.place(at: <#T##CGPoint#>, anchor: <#T##UnitPoint#>, proposal: <#T##ProposedViewSize#>)
        }
    }
}

struct NativePhotoPicker: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Binding var error: Error?
    
    private var isShowingBarcodeSelectionView: Binding<Bool> {
        Binding(get: {
            selectedImage != nil
        }, set: { newValue in
            if !newValue {
                selectedImage = nil
            }
        })
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    
                    NativePhotoPickerRepresentable(selectedImage: $selectedImage, error: $error)
                }
            }
            .onChange(of: isPresented) { isPresentedStatus in
                if isPresentedStatus == false {
                    isShowingBarcodeSelectionView.wrappedValue = false
                }
            }
    }
}

extension View {
    func nativePhotoPicker(isPresented: Binding<Bool>, selectedImage: Binding<UIImage?>, error: Binding<Error?>) -> some View {
        self.modifier(NativePhotoPicker(isPresented: isPresented, selectedImage: selectedImage, error: error))
    }
}

struct NativePhotoPicker_Previews: PreviewProvider {
    @State static var isPresented = true
    @State static var selectedImage: UIImage? = nil
    @State static var error: Error? = nil
    
    static var previews: some View {
        Text("Hello, world!")
            .modifier(NativePhotoPicker(isPresented: $isPresented, selectedImage: $selectedImage, error: $error))
    }
}
