import SwiftUI
import AVFoundation

// TODO: https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types

enum BarcodeType: String, Codable {
    case code128 = "Barcode"
    case qr = "QR Code"
}

struct Coupon: Identifiable, Codable {
    var id = UUID()
    let name: String
    let code: String
    var balance: Double
    let expirationDate: Date
    let barcodeType: BarcodeType
}
