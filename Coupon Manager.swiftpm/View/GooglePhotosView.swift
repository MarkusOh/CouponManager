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
    
    var body: some View {
        NavigationStack {
            ZStack {
                if photosProvider.isGooglePhotosAvailable {
                    photosView
                } else {
                    authenticationView
                }
                
                if let errorReminder = photosProvider.errorReminder {
                    Text("Error: \(errorReminder.localizedDescription)")
                        .padding(.all)
                        .foregroundColor(.white)
                        .background(.gray)
                        .padding(.all)
                        .opacity(0.8)
                }
            }.toolbar {
                ToolbarItem(placement: .navigationBarLeading, content: {
                    Button(action: {
                        // TODO: Remove Google Photos View
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
            GooglePhotosGridView(googlePhotoItems: photosProvider.availablePhotos, imageTapAction: { imageUrl in
                // TODO: Detect barcode from imageURL
            }, endOfGridAction: photosProvider.attemptToFetchMorePhotos)
        }
    }
    
    var authenticationView: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    Text("To use Google Photos, you need to login to Google\n and give us permission to access your library.")
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

struct GooglePhotosView_Previews: PreviewProvider {
    @State static var errorMessage: ErrorMessage = .empty
    @State static var errorShow: Bool = false
    
    static var previews: some View {
        GooglePhotosView(googlePhotosError: $errorMessage, googlePhotosErrorShow: $errorShow)
    }
}
