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
                CompatibilityNavigationStack {
                    CompatibilityNavigationLink(mainBody: {
                        NativePhotoPickerRepresentable(selectedImage: $selectedImage, error: $error)
                    }, destination: {
                        BarcodeSelectionView(localImage: selectedImage, url: nil, error: $error, isPresented: $isPresented)
                    }, isPresented: isShowingBarcodeSelectionView)
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
