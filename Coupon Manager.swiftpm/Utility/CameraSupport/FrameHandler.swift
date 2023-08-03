import SwiftUI
import AVFoundation
import CoreImage
import Combine

struct BoundingBoxInfo: Identifiable {
    var id: UUID = UUID()
    let box: CGRect
    let barcode: String?
    let type: BarcodeType
}

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    
    @Published var boundingBoxes: [BoundingBoxInfo] = []
    var detectedBarcodes: [String?] = []
    var detectedBarcodeTypes: [BarcodeType?] = []
    
    private var captureSession = AVCaptureSession()
    private let context = CIContext()
    
    var videoOrientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            guard oldValue != videoOrientation,
                  let output = captureSession.outputs.first as? AVCaptureVideoDataOutput else { return }
            output.connection(with: .video)?.videoOrientation = videoOrientation
        }
    }
    
    override init() {
        super.init()
        
        let imagePublisher = $frame
            .compactMap { $0 }
            .throttle(for: .seconds(0.25), scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
        
        Task { [weak self] in
            guard await self?.checkPermission() ?? false else { return }
            self?.setupCaptureSession()
            self?.captureSession.startRunning()
            
            for await newImage in imagePublisher.values {
                let orientation = await FrameHandler.returnOrientation(from: UIDevice.current.orientation)
                guard let observations = try? await BarcodeDetectorFromImage.performBarcodeDetection(from: newImage, cgImageOrientation: orientation) else {
                    await MainActor.run { [weak self] in
                        self?.boundingBoxes = []
                        self?.detectedBarcodes = []
                        self?.detectedBarcodeTypes = []
                    }
                    continue
                }
                
                let boundingBoxes =
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
                
                await MainActor.run { [weak self] in
                    self?.boundingBoxes = boundingBoxes
                }
            }
        }
    }
    
    func checkPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else { return }
        
        captureSession.addInput(videoDeviceInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferDelegate"))
        
        captureSession.addOutput(videoOutput)
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
    }
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.frame = cgImage
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }
}

extension FrameHandler {
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
