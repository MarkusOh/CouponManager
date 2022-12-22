import SwiftUI
import Vision
import AVFoundation

// https://www.avanderlee.com/swift/async-await/
// https://betterprogramming.pub/detecting-objects-in-still-images-using-vision-framework-in-ios-82877bc87703
// https://www.kodeco.com/12663654-vision-framework-tutorial-for-ios-scanning-barcodes

enum BarcodeDetectorError: Error {
    case barcodeNotFound
    case cgImageNotFound
    case isBarcodeFetcherPreoccupied
}

class BarcodeDetectorFromImage {
    static func fetchBarcodeString(from image: UIImage) async throws -> (String, AVMetadataObject.ObjectType) {
        guard let cgImage = image.cgImage else {
            throw BarcodeDetectorError.cgImageNotFound
        }
        
        let observation = try await performBarcodeDetection(from: cgImage, cgImageOrientation: CGImagePropertyOrientation(image.imageOrientation))
        
        guard let barcodeString = observation.payloadStringValue else {
            throw BarcodeDetectorError.barcodeNotFound
        }
        
        switch observation.symbology {
        case .code128: return (barcodeString, .code128)
        case .qr: return (barcodeString, .qr)
        default: return (barcodeString, .code128)
        }
    }
    
    static func performBarcodeDetection(from cgImage: CGImage, cgImageOrientation: CGImagePropertyOrientation) async throws -> VNBarcodeObservation {
        return try await withCheckedThrowingContinuation({ continuation in
            let request = VNDetectBarcodesRequest(completionHandler: { request, error in
                guard error == nil else {
                    continuation.resume(throwing: error!)
                    return
                }
                
                guard let observations = request.results as? [VNBarcodeObservation],
                      let observation = observations.first else {
                    continuation.resume(throwing: BarcodeDetectorError.barcodeNotFound)
                    return
                }
                
                continuation.resume(returning: observation)
            })
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgImageOrientation, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)                
            }
        })
    }
}

extension CGImagePropertyOrientation {    
    init(_ orientation: UIImage.Orientation) {  
        switch orientation {  
        case .up: self = .up  
        case .upMirrored: self = .upMirrored  
        case .down: self = .down  
        case .downMirrored: self = .downMirrored  
        case .left: self = .left  
        case .leftMirrored: self = .leftMirrored  
        case .right: self = .right  
        case .rightMirrored: self = .rightMirrored  
        @unknown default: fatalError("WARNING: Unknown Orientation Found")
        }  
    }  
}  
