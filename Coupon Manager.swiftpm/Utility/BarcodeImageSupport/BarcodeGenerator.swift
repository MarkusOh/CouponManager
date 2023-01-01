import SwiftUI

struct BarcodeGenerator {
    enum BarcodeType {
        case barcode, qrcode
    }
    
    static func generateBarcode(from string: String, with type: BarcodeType) -> UIImage? {
        let barcodeGenerator = type == .barcode ? "CICode128BarcodeGenerator" : "CIQRCodeGenerator"
        
        guard let data = string.data(using: String.Encoding.ascii),
              let filter = CIFilter(name: barcodeGenerator, parameters: [ "inputMessage": data ]) else {
            return nil
        }
        
        let transform = CGAffineTransform(scaleX: 4, y: 4)
        
        guard let output = filter.outputImage?.transformed(by: transform),
              let data = UIImage(ciImage: output).pngData(),
              let uiImage = UIImage(data: data) else {
            return nil
        }
        
        return uiImage
    }
    
    static func generateBarcode(from string: String) -> UIImage? {
        return generateBarcode(from: string, with: .barcode)
    }
    
    static func generateBarcodeView(from string: String) -> Image? {
        guard let image = BarcodeGenerator.generateBarcode(from: string) else {
            return nil
        }
        
        return Image(uiImage: image)
    }
    
    static func generateQRCode(from string: String) -> UIImage? {
        return generateBarcode(from: string, with: .qrcode)
    }
    
    static func generateQRCodeView(from string: String) -> Image? {
        guard let image = BarcodeGenerator.generateQRCode(from: string) else {
            return nil
        }
        
        return Image(uiImage: image)
    }
    
    static func barcodeImageViewGenerate(with coupon: Coupon) -> Image? {
        if coupon.barcodeType == .code128 {
            return BarcodeGenerator.generateBarcodeView(from: coupon.code)
        } else { // barcodeType == "QR Code"
            return BarcodeGenerator.generateQRCodeView(from: coupon.code)
        }
    }
}
