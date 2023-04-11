//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/26.
//

import SwiftUI

enum GooglePhotosViewError: Error {
    case unsuccessfulResponseCode
    case dataToImageConversionFail
}

struct GooglePhotosView: View {
    // TODO: There is no way to pass the error from photosProvider to here.
    @ObservedObject var photosProvider = GooglePhotosDataProvider.shared
    
    @State private var loginError: Error? = nil
    @State private var errorMessagePositionOffset: Double = 0
    
    @Binding var isPresented: Bool
    @Binding var error: Error?
    
    var body: some View {
        CompatibilityNavigationStack {
            ZStack {
                if photosProvider.isGooglePhotosAvailable {
                    photosView
                } else {
                    authenticationView
                }
                
                if loginError != nil {
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                                .frame(height: geo.size.height - errorMessagePositionOffset)
                                .task { @MainActor in
                                    withAnimation(.spring(blendDuration: 0.5)) {
                                        errorMessagePositionOffset = 150
                                    }
                                    
                                    try! await Task.sleep(nanoseconds: 3_000_000_000)
                                    
                                    withAnimation(.spring(blendDuration: 0.5)) {
                                        errorMessagePositionOffset = 0
                                    }
                                    
                                    try! await Task.sleep(nanoseconds: 500_000_000)
                                    
                                    loginError = nil
                                }
                            SnackBarView(title: "아이구! 로그인 중 에러가 있었습니다", message: loginError?.localizedDescription ?? "에러가 없습니다")
                                .opacity(errorMessagePositionOffset / 150)
                        }
                    }
                }
            }
            .toolbar {
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
            GooglePhotosGridView(googlePhotoItems: photosProvider.availablePhotos, endOfGridAction: photosProvider.attemptToFetchMorePhotos, error: $error, isPresented: $isPresented)
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
                .background(Color.white)
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
                loginError = error
                return
            }
            
            guard didUserSignIn else {
                loginError = GoogleSignInAndConsentError.userDidNotLogin
                return
            }
            
            let didUserConsent: Bool
            do {
                didUserConsent = try await GooglePhotosDataProvider.shared.askForUsersConsent()
            } catch {
                loginError = GoogleSignInAndConsentError.userDidNotChoose
                return
            }
            
            guard didUserConsent else {
                loginError = GoogleSignInAndConsentError.userDidNotGiveAccessPermission
                return
            }
        }
    }
}

enum GoogleSignInAndConsentError: Error {
    case userDidNotLogin
    case userDidNotChoose
    case userDidNotGiveAccessPermission
}

struct GooglePhotosPicker: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var error: Error?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, content: {
                GooglePhotosView(isPresented: $isPresented, error: $error)
            })
    }
}

extension View {
    func googlePhotosPicker(isPresented: Binding<Bool>, selectedPhoto: Binding<UIImage?>, error: Binding<Error?>) -> some View {
        self.modifier(GooglePhotosPicker(isPresented: isPresented, error: error))
    }
}

struct GooglePhotosView_Previews: PreviewProvider {
    @State static var isPresented = true
    @State static var error: Error?
    
    static var previews: some View {
        GooglePhotosView(isPresented: $isPresented, error: $error)
    }
}
