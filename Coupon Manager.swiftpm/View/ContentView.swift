import AVFoundation
import PhotosUI
import SwiftUI
import GoogleSignIn

struct ErrorMessage {
    static let empty: ErrorMessage = ErrorMessage(title: "", detail: "")
    
    var title: String
    var detail: String
}

enum ContentViewError: Error {
    case dataToUIImageFail
    case nilFound
    case unableToLoadTransferable
}

struct ContentView: View {
    @State private var isShowingScanner = false
    @State private var isShowingPhotoPicker = false
    
    // Error Title and Message
    @State private var error: Error? = nil
    
    @State private var errorMessage = ErrorMessage.empty
    @State private var isShowingError = false
    
    // Sheet View for getting balance and expiration date from User
    @State private var isShowingInputSheet = false
    @State private var couponCode = ""
    @State private var couponBarcodeType: BarcodeType = .code128
    
    @StateObject var dataProvider = CouponDataProvider.shared
    
    @State private var isShowingGooglePhotosView = false
    
    @State private var selectedPhoto: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            barcodeList
        }
        .sheet(isPresented: $isShowingScanner) { 
            cameraScannerView
                .presentationDetents([ .medium ])
        }
        .modifier(ErrorAlert(isShowingError: $isShowingError, errorMessage: errorMessage))
        .sheet(isPresented: $isShowingInputSheet, content: {
            CouponInfoInputView(couponCode: $couponCode, barcodeType: $couponBarcodeType, inputCompletionHandler: { receivedCoupon in
                dataProvider.create(coupon: receivedCoupon)
            }).presentationDetents([ .medium ])
        })
        .googlePhotosPicker(isPresented: $isShowingGooglePhotosView, selectedPhoto: $selectedPhoto, error: $error)
        .nativePhotoPicker(isPresented: $isShowingPhotoPicker, selectedImage: $selectedPhoto, error: $error)
        .onChange(of: selectedPhoto) { newImage in
            guard let newImage = newImage else {
                return
            }
            
            Task(priority: .background) {
                do {
                    let result = try await fetchCodeAndType(from: newImage)
                    handleScan(result: .success(result))
                } catch {
                    handleScan(result: .failure(error))
                }
            }
        }
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
                Menu {
                    Button("포토앨범") {
                        isShowingPhotoPicker.toggle()
                    }
                    Button("카메라") {
                        isShowingScanner.toggle()
                    }
                    Button("Google Photos", action: {
                        isShowingGooglePhotosView.toggle()
                    })
                } label: {
                    Image(systemName: "plus")
                }
            })
        })
        .alert(isPresented: $isShowingError) {
            Alert(title: Text(errorMessage.title), message: Text(errorMessage.detail), dismissButton: .default(Text("OK")))
        }
    }
    
    var cameraScannerView: some View {
        GeometryReader { geometry in
            CameraView { barcodeString, barcodeType  in
                handleScan(result: .success((barcodeString, barcodeType)))
            }.frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }
    
    func fetchCodeAndType(from uiImage: UIImage) async throws -> (String, BarcodeType) {
        let observationResult = try await BarcodeDetectorFromImage.fetchBarcodeString(from: uiImage)
        return observationResult
    }
    
    func handleScan(result: Result<(String, BarcodeType), Error>) {
        isShowingScanner = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch result {
            case .success(let (barcodeString, barcodeType)):
                couponCode = barcodeString
                couponBarcodeType = barcodeType
                isShowingInputSheet.toggle()
                
            case .failure(let resultError):
                errorMessage.title = "Error Found"
                errorMessage.detail = resultError.localizedDescription
                isShowingError.toggle()
            }
        }
    }
}
