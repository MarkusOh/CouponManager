//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/01/19.
//

import SwiftUI
import Vision

enum BarcodeSelectionViewError: Error {
    case imageConversionFailed(detail: String)
}

struct BarcodeSelectionView: View {
    @State private var image: UIImage?
    
    let localImage: UIImage?
    let url: URL?
    
    @Binding var error: Error?
    @Binding var isPresented: Bool
    @State private var allBoundingBoxInfo: [BoundingBoxInfo]?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            if let allBoundingBoxInfo = allBoundingBoxInfo {
                ForEach(allBoundingBoxInfo) { info in
                    BoxTouchView(boundingBoxInfo: info, sourceImageAspectRatio: image!.size.width / image!.size.height, isPresented: $isPresented)
                }
            } else {
                Text("감지된 바코드가 없습니다!")
                    .foregroundColor(Color(red: 0.90, green: 0.22, blue: 0.27))
                    .padding(20)
                    .padding(.horizontal)
                    .background(Color.accentColor.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .onAppear {
            if let localImage = localImage {
                image = localImage
                detectAllBoundingBoxFromImage(image: localImage)
            } else if let url = url {
                handleSelectedImage(imageUrl: url)
            }
        }
        .onChange(of: image) { newImage in
            guard let newImage = newImage else { return }
            detectAllBoundingBoxFromImage(image: newImage)
        }
    }
    
    func handleSelectedImage(imageUrl: URL) {
        Task {
            do {
                let (data, response) = try await URLSession(configuration: .default).data(for: URLRequest(url: imageUrl))
                let responseCode = (response as! HTTPURLResponse).statusCode
                
                guard (200..<300).contains(responseCode) else {
                    throw GooglePhotosViewError.unsuccessfulResponseCode
                }
                
                guard let image = UIImage(data: data) else {
                    throw GooglePhotosViewError.dataToImageConversionFail
                }
                
                self.image = image
            } catch {
                self.error = error
            }
        }
    }
    
    func detectAllBoundingBoxFromImage(image: UIImage) {
        Task {
            guard let ciImage = CIImage(image: image) else {
                error = BarcodeSelectionViewError.imageConversionFailed(detail: "UIView → CIImage Conversion Failed")
                return
            }
            
            guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
                error = BarcodeSelectionViewError.imageConversionFailed(detail: "CIContext createCGImage Failed")
                return
            }
            
            let observations: [VNBarcodeObservation]
            do {
                observations = try await BarcodeDetectorFromImage.performBarcodeDetection(from: cgImage, cgImageOrientation: CGImagePropertyOrientation(image.imageOrientation))
            } catch {
                self.error = error
                return
            }
            
            let allInfo =
                observations.map { observation -> BoundingBoxInfo? in
                    let supportedBarcodeType: BarcodeType?
                    switch observation.symbology {
                    case .code128: supportedBarcodeType = .code128
                    case .qr: supportedBarcodeType = .qr
                    default: supportedBarcodeType = nil
                    }
                    
                    guard let supportedBarcodeType = supportedBarcodeType else {
                        return nil
                    }
                    
                    return BoundingBoxInfo(box: observation.boundingBox, barcode: observation.payloadStringValue, type: supportedBarcodeType)
                }.compactMap({ $0 })
            
            allBoundingBoxInfo = allInfo
        }
    }
}

struct BarcodeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BarcodeSelectionView(localImage: nil, url: nil, error: .constant(nil), isPresented: .constant(true))
    }
}
