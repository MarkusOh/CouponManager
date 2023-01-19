//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2023/01/19.
//

import SwiftUI

struct BoxTouchView: View {
    let boundingBoxInfo: BoundingBoxInfo
    let sourceImageAspectRatio: Double
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationLink {
            CouponInfoInputView(couponCode: boundingBoxInfo.barcode ?? "", barcodeType: boundingBoxInfo.type, isPresented: $isPresented)
        } label: {
            BoxView(detectedBox: boundingBoxInfo.box, sourceImageAspectRatio: sourceImageAspectRatio)
                .stroke(.teal, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                .background(
                    BoxView(detectedBox: boundingBoxInfo.box, sourceImageAspectRatio: sourceImageAspectRatio).fill(.teal.opacity(0.2))
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(
            BoxView(detectedBox: boundingBoxInfo.box, sourceImageAspectRatio: sourceImageAspectRatio)
        )
    }
}

struct BoxView: Shape {
    let detectedBox: CGRect
    let sourceImageAspectRatio: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let currentAspectRatio = rect.width / rect.height
        
        let realWidth: Double
        let realHeight: Double
        if currentAspectRatio < sourceImageAspectRatio {
            // shrink the height
            realWidth = rect.width
            realHeight = rect.height * (currentAspectRatio / sourceImageAspectRatio)
        } else {
            // shrink the width
            realWidth = rect.width * (sourceImageAspectRatio / currentAspectRatio)
            realHeight = rect.height
        }
        
        let offsetWidth = (rect.width - realWidth) / 2
        let offsetHeight = (rect.height - realHeight) / 2
        
        let absoluteBox = CGRect(x: realWidth * detectedBox.origin.x + offsetWidth,
                                 y: realHeight * (1 - detectedBox.origin.y) - realHeight * detectedBox.height + offsetHeight,
                                 width: realWidth * detectedBox.width,
                                 height: realHeight * detectedBox.height)
        path.addRect(absoluteBox)
        return path
    }
}
