import SwiftUI
import Combine

struct CameraView: View {
    @State private var image: CGImage?
    @StateObject private var model = FrameHandler()
    let imageHandler: (CGImage) -> Void
    
    var body: some View {
        if let image = model.frame {
            ZStack {
                FrameView(image: image)
                if !model.boundingBoxes.isEmpty {
                    ForEach(0..<model.boundingBoxes.count, id: \.hashValue) { (boxIndex) in
                        BoxView(detectedBox: model.boundingBoxes[boxIndex])
                            .stroke(.red, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        } else {
            GeometryReader { geometry in
                Text("No Camera Available")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(.black)
            }
        }
    }
}

struct BoxView: Shape {
    let detectedBox: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.width * detectedBox.origin.x, y: rect.height * (1 - detectedBox.origin.y)))
        path.addLine(to: CGPoint(x: rect.width * detectedBox.origin.x + rect.width * detectedBox.width,
                                 y: rect.height * (1 - detectedBox.origin.y)))
        path.addLine(to: CGPoint(x: rect.width * detectedBox.origin.x + rect.width * detectedBox.width,
                                 y: rect.height * (1 - detectedBox.origin.y) - rect.height * detectedBox.height))
        path.addLine(to: CGPoint(x: rect.width * detectedBox.origin.x,
                                 y: rect.height * (1 - detectedBox.origin.y) - rect.height * detectedBox.height))
        path.addLine(to: CGPoint(x: rect.width * detectedBox.origin.x, y: rect.height * (1 - detectedBox.origin.y)))
        path.closeSubpath()
        
        return path
    }
}
