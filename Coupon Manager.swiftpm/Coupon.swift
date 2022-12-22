import SwiftUI
import AVFoundation

// TODO: https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types
struct Coupon: Identifiable, Codable {
    var id = UUID()
    let code: String
    var balance: Double
    let expirationDate: Date
    let barcodeType: String
}
