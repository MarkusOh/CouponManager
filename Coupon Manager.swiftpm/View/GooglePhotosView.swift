//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/26.
//

import SwiftUI

struct GooglePhotosView: View {
    // TODO: There is no way to pass the error from photosProvider to here.
    @ObservedObject var photosProvider = GooglePhotosDataProvider.shared
    
    @State private var errorMessage = ErrorMessage.empty
    @State private var isShowingError = false
    
    @Binding var isPresented: Bool
    @Binding var selectedPhoto: UIImage?
    @Binding var error: Error?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if photosProvider.isGooglePhotosAvailable {
                    photosView
                } else {
                    authenticationView
                }
                
                SnackBarView(isShowing: $isShowingError, title: errorMessage.title, message: errorMessage.detail)
            }.toolbar {
                ToolbarItem(placement: .navigationBarLeading, content: {
                    Button(action: {
                        isPresented.toggle()
                    }, label: {
                        Text("Cancel")
                    })
                })
            }
            .navigationTitle("Google Photos")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var photosView: some View {
        GeometryReader { geometry in
            GooglePhotosGridView(googlePhotoItems: photosProvider.availablePhotos, imageTapAction: handleSelectedImage, endOfGridAction: photosProvider.attemptToFetchMorePhotos)
        }
    }
    
    func handleSelectedImage(imageUrl: URL) {
        Task {
            do {
                let (data, response) = try await URLSession(configuration: .default).data(for: URLRequest(url: imageUrl))
                let responseCode = (response as! HTTPURLResponse).statusCode
                
                guard (200..<300).contains(responseCode) else {
                    throw GooglePhotoAlbumsProviderError.unsuccessfulResponseCode
                }
                
                selectedPhoto = UIImage(data: data)!
                isPresented.toggle()
            } catch {
                // TODO: If failed, tell the user why the image fetching failed
            }
        }
    }
    
    var authenticationView: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .foregroundColor(.yellow)
                            .frame(width: 30, height: 30)
                            .padding(.bottom, 8)
                        Spacer()
                    }
                    Text("Google Photos 사용 전, Google 로그인과 라이브러리 접근 권한이 필요합니다")
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    Button("Sign in with Google", action: signInAndConsentAction)
                        .padding(.all, 10)
                        .padding(.horizontal, 10)
                        .font(.system(.body).bold())
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .shadow(radius: 5)
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(maxWidth: 320)
                .shadow(radius: 5)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    func signInAndConsentAction() {
        Task(priority: .userInitiated) {
            let didUserSignIn: Bool
            do {
                didUserSignIn = try await GooglePhotosDataProvider.shared.askForUserSignIn()
            } catch {
                errorMessage = ErrorMessage(title: "로그인 중 오류 발견", detail: error.localizedDescription)
                isShowingError = true
                return
            }
            
            guard didUserSignIn else {
                errorMessage = ErrorMessage(title: "사용자가 로그인하지 않음", detail: "Google Photo 를 사용하려면 로그인하세요.")
                isShowingError = true
                return
            }
            
            let didUserConsent: Bool
            do {
                didUserConsent = try await GooglePhotosDataProvider.shared.askForUsersConsent()
            } catch {
                errorMessage = ErrorMessage(title: "로그인 중 오류 발견", detail: error.localizedDescription)
                isShowingError = true
                return
            }
            
            guard didUserConsent else {
                errorMessage = ErrorMessage(title: "사용자가 동의하지 않음", detail: "Google 포토 라이브러리를 사용하려면 앱에서 라이브러리에 액세스할 수 있도록 허용하세요.")
                isShowingError = true
                return
            }
        }
    }
}

struct GooglePhotosPicker: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedPhoto: UIImage?
    @Binding var error: Error?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, content: {
                GooglePhotosView(isPresented: $isPresented, selectedPhoto: $selectedPhoto, error: $error)
            })
    }
}

extension View {
    func googlePhotosPicker(isPresented: Binding<Bool>, selectedPhoto: Binding<UIImage?>, error: Binding<Error?>) -> some View {
        self.modifier(GooglePhotosPicker(isPresented: isPresented, selectedPhoto: selectedPhoto, error: error))
    }
}

struct GooglePhotosView_Previews: PreviewProvider {
    @State static var isPresented = true
    @State static var selectedPhoto: UIImage?
    @State static var error: Error?
    
    static var previews: some View {
        GooglePhotosView(isPresented: $isPresented, selectedPhoto: $selectedPhoto, error: $error)
    }
}
