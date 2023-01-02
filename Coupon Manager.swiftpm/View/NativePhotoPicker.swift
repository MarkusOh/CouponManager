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
    
    @State private var photosPickerItem: PhotosPickerItem? = nil
    
    func body(content: Content) -> some View {
        content
            .photosPicker(isPresented: $isPresented, selection: $photosPickerItem, matching: .images)
            .onChange(of: photosPickerItem) { photo in
                guard let photo = photo else { return }
                
                Task(priority: .userInitiated) {
                    do {
                        let data = try await photo.loadTransferable(type: Data.self)
                        
                        guard let data = data else {
                            throw NativePhotoPickerError.dataUnavailable
                        }
                        
                        guard let image = UIImage(data: data) else {
                            throw NativePhotoPickerError.imageUnavailable
                        }
                        
                        selectedImage = image
                        
                    } catch {
                        self.error = error
                    }
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
