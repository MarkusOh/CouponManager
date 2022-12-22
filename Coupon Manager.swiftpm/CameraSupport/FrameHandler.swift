import SwiftUI
import AVFoundation
import CoreImage

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
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
        
        Task { [weak self] in
            guard await checkPermission() else { return }
            self?.setupCaptureSession()
            self?.captureSession.startRunning()
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
