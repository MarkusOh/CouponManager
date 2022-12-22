import SwiftUI
import Combine

struct CameraView: View {
    @StateObject private var model = FrameHandler()
    let imageHandler: (CGImage) -> Void
    
    var body: some View {
        if let image = model.frame {
            ZStack {
                FrameView(image: image)
                VStack {
                    Spacer()
                    Spacer()
                    Button("이미지 사용", action: {
                        imageHandler(image)
                    })
                    Spacer()
                }
            }
        } else {
            Text("No Camera Available")
                .colorScheme(.dark)
                .background(.black)
        }
    }
}
