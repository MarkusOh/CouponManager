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
    
    // Error Title and Message
    @State private var errorMessage = ErrorMessage.empty
    @State private var isShowingError = false
    
    // Sheet View for getting balance and expiration date from User
    @State private var isShowingInputSheet = false
    @State private var couponCode = ""
    @State private var couponBarcodeType: BarcodeType = .code128
    
    @StateObject var dataProvider = CouponDataProvider.shared
    
    @State private var isShowingGooglePhotosView = false
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    
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
        .sheet(isPresented: $isShowingGooglePhotosView, content: {
            GooglePhotosAlbumView(googlePhotosError: $errorMessage, googlePhotosErrorShow: $isShowingError)
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
                Menu {
                    Button("포토앨범") {
                        // TODO: Show Photo Album View
                    }
                    Button("카메라") {
                        // TODO: Show Camera View
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
            Task(priority: .background) {
                do {
                    guard let newItem = newItem else { throw ContentViewError.nilFound }
                    let data = try await newItem.loadTransferable(type: Data.self)
                    guard let data = data else { throw ContentViewError.unableToLoadTransferable }
                    let result = try await fetchCodeAndType(from: data)
                    handleScan(result: .success(result))
                } catch {
                    handleScan(result: .failure(error))
                }
            }
        })
    }
    
    var cameraScannerView: some View {
        GeometryReader { geometry in
            CameraView { barcodeString, barcodeType  in
                handleScan(result: .success((barcodeString, barcodeType)))
            }.frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }
    
    func fetchCodeAndType(from data: Data) async throws -> (String, BarcodeType) {
        guard let image = UIImage(data: data) else { throw ContentViewError.dataToUIImageFail }
        let observationResult = try await BarcodeDetectorFromImage.fetchBarcodeString(from: image)
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
