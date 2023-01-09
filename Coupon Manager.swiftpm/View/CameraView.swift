import SwiftUI
import Combine

struct CameraView: View {
    @StateObject private var model = FrameHandler()
    
    @State var couponCode: String?
    @State var couponBarcodeType: BarcodeType?
    
    private var isShowingInputSheet: Binding<Bool> {
        Binding(get: {
            couponCode != nil && couponBarcodeType != nil
        }, set: { newValue in
            if !newValue {
                couponCode = nil
                couponBarcodeType = nil
            }
        })
    }
    
    var body: some View {
        NavigationStack {
            cameraView
                .navigationDestination(isPresented: isShowingInputSheet) {
                    CouponInfoInputView(couponCode: couponCode ?? "", barcodeType: couponBarcodeType ?? .code128)
                }
                .navigationTitle("카메라")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var cameraView: some View {
        if let image = model.frame {
            return AnyView(ZStack {
                FrameView(image: image)
                if !model.boundingBoxes.isEmpty {
                    ForEach(0..<model.boundingBoxes.count, id: \.self) { (boxIndex) in
                        BoxTouchView(detectedBox: model.boundingBoxes[boxIndex], tapAction: {
                            guard boxIndex < model.detectedBarcodes.count,
                                  let tappedBarcode = model.detectedBarcodes[boxIndex],
                                  let tappedBarcodeType = model.detectedBarcodeTypes[boxIndex] else { return }
                            
                            couponCode = tappedBarcode
                            couponBarcodeType = tappedBarcodeType
                        })
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
                    CameraView()
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
