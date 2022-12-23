//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/23.
//

import SwiftUI
import Combine

class BoundingBoxHandler: ObservableObject {
    @Published var boundingBoxes: [CGRect] = []
    
    init(image: Published<CGImage?>.Publisher) {
        let publisher = image
            .removeDuplicates()
            .compactMap { $0 }
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.global(), latest: true)
            
        Task { [weak self] in
            for await fetchedImage in publisher.values {
                let orientation = await BoundingBoxHandler.returnOrientation(from: UIDevice.current.orientation)
                let observations = try await BarcodeDetectorFromImage.performBarcodeDetection(from: fetchedImage, cgImageOrientation: orientation)
                DispatchQueue.main.async { [weak self] in
                    self?.boundingBoxes = observations.map { $0.boundingBox }
                }
            }
        }
    }
    
    static func fetchBoundingBoxes(from image: CGImage) async throws -> [CGRect] {
        let observations = try await BarcodeDetectorFromImage.performBarcodeDetection(from: image, cgImageOrientation: returnOrientation(from: UIDevice.current.orientation))
        let boundinBoxes = observations.map { $0.boundingBox }
        return boundinBoxes
    }
    
    static func returnOrientation(from uiDeviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        switch uiDeviceOrientation {
        case .unknown:
            return .up
        case .portrait:
            return .up
        case .portraitUpsideDown:
            return .down
        case .landscapeLeft:
            return .left
        case .landscapeRight:
            return .right
        case .faceUp:
            return .up
        case .faceDown:
            return .up
        @unknown default:
            return .up
        }
    }
}
