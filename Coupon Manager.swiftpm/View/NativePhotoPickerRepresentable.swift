//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/02/25.
//

import SwiftUI
import PhotosUI

enum NativePhotoPickerRepresentableError: Error {
    case doesNotConformToUiImage
}

struct NativePhotoPickerRepresentable: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var error: Error?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        
        let vc = PHPickerViewController(configuration: configuration)
        vc.delegate = context.coordinator
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: NativePhotoPickerRepresentable
        
        init(parent: NativePhotoPickerRepresentable) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let loadableResults = results.filter({ $0.itemProvider.canLoadObject(ofClass: UIImage.self) })
            guard let firstResult = loadableResults.first else {
                return
            }
            
            firstResult.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] data, error in
                defer {
                    DispatchQueue.main.async {
                        picker.dismiss(animated: true)
                    }
                }
                
                guard error == nil else {
                    self?.parent.error = error
                    return
                }
                
                guard let image = data as? UIImage else {
                    self?.parent.error = NativePhotoPickerRepresentableError.doesNotConformToUiImage
                    return
                }
                
                self?.parent.selectedImage = image
            }
        }
    }
}
