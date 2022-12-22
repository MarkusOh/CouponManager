import SwiftUI

class CouponDataProvider: ObservableObject {
    static let shared = CouponDataProvider()
    private let dataSourceURL: URL
    @Published var allCoupons = [Coupon]()
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let couponsPath = documentsPath.appendingPathComponent("coupons").appendingPathExtension("json")
        dataSourceURL = couponsPath
        
        _allCoupons = Published(wrappedValue: getAllCoupons())
    }
    
    private func getAllCoupons() -> [Coupon] {
        do {
            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: dataSourceURL)
            let decodedCoupons = try! decoder.decode([Coupon].self, from: data)
            return decodedCoupons
        } catch {
            return []
        }
    }
    
    internal func saveCoupons() {
        do {
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(allCoupons)
            try data.write(to: dataSourceURL)
        } catch {
            print("Error while saving coupons \(error)")
        }
    }
    
    internal func setBalance(on coupon: Coupon, with newBalance: Double) {
        let newCoupon = Coupon(id: coupon.id, code: coupon.code, balance: newBalance, expirationDate: coupon.expirationDate, barcodeType: coupon.barcodeType)
        changeCoupon(coupon: newCoupon, index: allCoupons.firstIndex(where: { $0.id == coupon.id })!)
    }
    
    internal func create(coupon: Coupon) {
        allCoupons.insert(coupon, at: 0)
        saveCoupons()
    }
    
    fileprivate func changeCoupon(coupon: Coupon, index: Int) {
        allCoupons[index] = coupon
        saveCoupons()
    }
    
    internal func delete(_ offset: IndexSet) {
        allCoupons.remove(atOffsets: offset)
        saveCoupons()
    }
    
    internal func move(source: IndexSet, destination: Int) {
        allCoupons.move(fromOffsets: source, toOffset: destination)
        saveCoupons()
    }
}
