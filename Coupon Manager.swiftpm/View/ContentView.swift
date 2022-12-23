import AVFoundation
import PhotosUI
import SwiftUI

struct ErrorMessage {
    static let empty: ErrorMessage = ErrorMessage(title: "", detail: "")
    
    var title: String
    var detail: String
}

struct ContentView: View {
    @State private var moneyLeft = 100.0
    @State private var isShowingScanner = false
    
    // Error Title and Message
    @State private var errorMessage = ErrorMessage.empty
    @State private var isShowingError = false
    
    // Sheet View for getting balance and expiration date from User
    @State private var isShowingInputSheet = false
    @State private var couponCode = ""
    @State private var couponBarcodeType: BarcodeType = .code128
    
    @StateObject var dataProvider = CouponDataProvider.shared
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedPhotoImageData: Data? = nil {
        didSet {
            guard let selectedPhotoImageData = selectedPhotoImageData,
                  let image = UIImage(data: selectedPhotoImageData) else { return }
            
            Task(priority: .background) { 
                do {
                    let (barcodeString, barcodeType) = try await BarcodeDetectorFromImage.fetchBarcodeString(from: image)
                    self.couponBarcodeType = barcodeType
                    
                    handleScan(result: .success(barcodeString))
                } catch {
                    handleScan(result: .failure(error))
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            barcodeList
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $isShowingScanner) { 
            scannerView
                .presentationDetents([ .medium ])
        }
        .modifier(ErrorAlert(isShowingError: $isShowingError, errorMessage: errorMessage))
        .sheet(isPresented: $isShowingInputSheet, content: {
            CouponInfoInputView(couponCode: $couponCode, barcodeType: $couponBarcodeType, inputCompletionHandler: { receivedCoupon in
                dataProvider.create(coupon: receivedCoupon)
            }).presentationDetents([ .medium ])
        })
    }
}

struct ErrorAlert: ViewModifier {
    @Binding var isShowingError: Bool
    let errorMessage: ErrorMessage 
    
    func body(content: Content) -> some View {
        content
            .alert(errorMessage.title, isPresented: $isShowingError, actions: {
                Button("OK", action: {})
            }, message: {
                Text(errorMessage.detail)
            })
    }
}

extension ContentView {
    var barcodeList: some View {
        List { 
            ForEach(dataProvider.allCoupons) { coupon in
                CouponView(coupon: coupon, balanceSetterHandler: { newBalance in
                    dataProvider.setBalance(on: coupon, with: newBalance)
                })
            }
            .onDelete(perform: dataProvider.delete)
            .onMove(perform: dataProvider.move)
        }
        .navigationTitle("My쿠폰")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing, content: {
                Button(action: {
                    isShowingScanner.toggle()
                }, label: {
                    Image(systemName: "plus")
                })                
            })
        })
        .alert(isPresented: $isShowingError) {
            Alert(title: Text(errorMessage.title), message: Text(errorMessage.detail), dismissButton: .default(Text("OK")))
        }
    }
    
    var scannerView: some View {
        VStack {
            cameraScannerView
            imageSelectionView
        }
    }
    
    var imageSelectionView: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) { 
            Text("포토 앨범을 열어 사진 선택하기")
        }
        .onChange(of: selectedPhoto, perform: { newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else {
                    return
                }
                selectedPhotoImageData = data
            }
        })
    }
    
    var cameraScannerView: some View {
        GeometryReader { geometry in
            CameraView { (barcodeString, barcodeType) in
                couponBarcodeType = barcodeType
                handleScan(result: .success(barcodeString))
            }.frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }
    
    func handleScan(result: Result<String, Error>) {
        isShowingScanner = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch result {
            case .success(let result):
                couponCode = result
                isShowingInputSheet.toggle()
                
            case .failure(let resultError):
                errorMessage.title = "Error Found"
                errorMessage.detail = resultError.localizedDescription
                isShowingError.toggle()
            }
        }
    }
}
