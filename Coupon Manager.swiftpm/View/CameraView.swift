import SwiftUI
import Combine

struct CameraView: View {
    @StateObject private var model = FrameHandler()
    
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            cameraView
                .navigationTitle("카메라")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var cameraView: some View {
        if let image = model.frame {
            return AnyView(ZStack {
                FrameView(image: image)
                if !model.boundingBoxes.isEmpty {
                    ForEach(model.boundingBoxes) { boundingBox in
                        BoxTouchView(boundingBoxInfo: boundingBox, sourceImageAspectRatio: Double(image.width) / Double(image.height), isPresented: $isPresented)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            })
        } else {
            return AnyView(GeometryReader { geometry in
                Text("No Camera Available")
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(.black)
            })
        }
    }
}

struct CameraViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                GeometryReader { geometry in
                    CameraView(isPresented: $isPresented)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            }
    }
}

extension View {
    func cameraView(isPresented: Binding<Bool>, couponCode: Binding<String?>, couponBarcodeType: Binding<BarcodeType?>) -> some View {
        self.modifier(CameraViewModifier(isPresented: isPresented))
    }
}
