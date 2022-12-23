import SwiftUI
import Combine

struct CameraView: View {
    @StateObject private var model = FrameHandler()
    let detectedBarcodeHandler: (String, BarcodeType) -> Void
    
    var body: some View {
        if let image = model.frame {
            ZStack {
                FrameView(image: image)
                if !model.boundingBoxes.isEmpty {
                    ForEach(0..<model.boundingBoxes.count, id: \.self) { (boxIndex) in
                        BoxTouchView(detectedBox: model.boundingBoxes[boxIndex], tapAction: {
                            guard boxIndex < model.detectedBarcodes.count,
                                  let tappedBarcode = model.detectedBarcodes[boxIndex],
                                  let tappedBarcodeType = model.detectedBarcodeTypes[boxIndex] else { return }
                            detectedBarcodeHandler(tappedBarcode, tappedBarcodeType)
                        })
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

struct BoxTouchView: View {
    let detectedBox: CGRect
    let tapAction: () -> Void
    
    var body: some View {
        BoxView(detectedBox: detectedBox)
            .stroke(.teal, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
            .background(BoxView(detectedBox: detectedBox).fill(.teal.opacity(0.2)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture { _ in
                tapAction()
            }
    }
}

struct BoxView: Shape {
    let detectedBox: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let absoluteBox = CGRect(x: rect.width * detectedBox.origin.x,
                                 y: rect.height * (1 - detectedBox.origin.y) - rect.height * detectedBox.height,
                                 width: rect.width * detectedBox.width,
                                 height: rect.height * detectedBox.height)
        path.addRect(absoluteBox)
        return path
    }
}
