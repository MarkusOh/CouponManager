import SwiftUI
import AVFoundation
import CoreImage

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    private var permissionGranted = false
    private var captureSession = AVCaptureSession()
    private var sessionQueue = DispatchQueue(label: "sessionQueue", qos: .background)
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
        
        checkPermission()
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
            self?.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: 
            permissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                self?.permissionGranted = isGranted
            }
        default:
            permissionGranted = false
        }
    }
    
    func setupCaptureSession() {
        guard permissionGranted,
              let videoDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back),
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
