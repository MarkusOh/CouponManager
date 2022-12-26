//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/26.
//

import SwiftUI

struct GooglePhotosView: View {
    @ObservedObject var photosProvider = GooglePhotosDataProvider.shared
    
    @Binding var googlePhotosError: ErrorMessage
    @Binding var googlePhotosErrorShow: Bool
    
    @State private var errorMessage = ErrorMessage.empty
    @State private var isShowingError = false
    
    static let imageSize = 80.0
    
    var body: some View {
        ZStack {
            if photosProvider.isGooglePhotosAvailable {
                photosView
            } else {
                authenticationView
            }
            if let errorReminder = photosProvider.errorReminder {
                Text("Error: \(errorReminder.localizedDescription)")
            }
        }
    }
    
    var photosView: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: GooglePhotosView.imageSize))], spacing: 10) {
                    ForEach(Array(photosProvider.availablePhotos.enumerated()), id: \.element.id) { (index, photo) in
                        Button {
                            // TODO: Fetch photo to detect barcode
                            
                        } label: {
                            AsyncImage(url: URL(string: photo.baseUrl.absoluteString.appending("=w600-h600"))!, content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .imageIconModifier()
                            }, placeholder: {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .imageIconModifier()
                            })
                            .padding(.all)
                        }
                        .onAppear {
                            guard index == photosProvider.availablePhotos.count - 1 else {
                                return
                            }
                            
                            photosProvider.attemptToFetchMorePhotos()
                        }
                    }
                }
            }
        }
    }
    
    var authenticationView: some View {
        GeometryReader { geometry in
            VStack {
                Button("Sign in with Google", action: signInAndConsentAction)
                    .padding(.all, 10)
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(radius: 1, x: 1.5, y: 1.5)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    func signInAndConsentAction() {
        Task(priority: .userInitiated) {
            let didUserSignIn: Bool
            do {
                didUserSignIn = try await GooglePhotosDataProvider.shared.askForUserSignIn()
            } catch {
                errorMessage = ErrorMessage(title: "Error found during Sign in", detail: error.localizedDescription)
                isShowingError = true
                return
            }
            
            guard didUserSignIn else {
                errorMessage = ErrorMessage(title: "User did not sign in", detail: "Please sign in to use Google Photos library")
                isShowingError = true
                return
            }
            
            let didUserConsent: Bool
            do {
                didUserConsent = try await GooglePhotosDataProvider.shared.askForUsersConsent()
            } catch {
                errorMessage = ErrorMessage(title: "Error found during Sign in", detail: error.localizedDescription)
                isShowingError = true
                return
            }
            
            guard didUserConsent else {
                errorMessage = ErrorMessage(title: "User did not consent", detail: "Please allow our app to access your library to use Google Photos library")
                isShowingError = true
                return
            }
        }
    }
}

fileprivate struct ImageIconModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: GooglePhotosView.imageSize, height: GooglePhotosView.imageSize)
            .clipShape(Rectangle())
    }
}

extension View {
    fileprivate func imageIconModifier() -> some View {
        self.modifier(ImageIconModifier())
    }
}
