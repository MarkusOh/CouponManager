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
    let image: UIImage
    
    @Binding var error: Error?
    @Binding var isPresented: Bool
    @State private var allBoundingBoxInfo: [BoundingBoxInfo]?
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            if let allBoundingBoxInfo = allBoundingBoxInfo {
                ForEach(allBoundingBoxInfo) { info in
                    BoxTouchView(boundingBoxInfo: info, sourceImageAspectRatio: image.size.width / image.size.height, isPresented: $isPresented)
                }
            } else {
                Text("감지된 바코드가 없습니다!")
                    .foregroundColor(.red)
                    .padding(20)
                    .padding(.horizontal)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 15)
            }
        }
        .task {
            await detectAllBoundingBoxFromImage(image: image)
        }
    }
    
    func detectAllBoundingBoxFromImage(image: UIImage) async {
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

struct BarcodeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        BarcodeSelectionView(image: UIImage(), error: .constant(nil), isPresented: .constant(true))
    }
}
