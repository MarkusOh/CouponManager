import SwiftUI

struct FrameView: View {
    @State private var orientation = UIDeviceOrientation.unknown
    private var cgImageOrientation: Image.Orientation {
        switch orientation {
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
    
    let image: CGImage
    let label = Text("FrameView")
    
    var body: some View {
        Image(image, scale: 1.0, orientation: cgImageOrientation, label: label)
            .resizable()
            .scaledToFill()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification), perform: { _ in
                orientation = UIDevice.current.orientation
            })
    }
}
