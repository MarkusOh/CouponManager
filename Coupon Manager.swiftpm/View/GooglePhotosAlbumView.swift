//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/26.
//

import SwiftUI

struct GooglePhotosAlbumView: View {
    @ObservedObject var photosAlbumsProvider = GooglePhotoAlbumsProvider.shared
    
    @Binding var googlePhotosError: ErrorMessage
    @Binding var googlePhotosErrorShow: Bool
    
    @State private var errorMessage = ErrorMessage.empty
    @State private var isShowingError = false
    
    var body: some View {
        if photosAlbumsProvider.isGooglePhotosAvailable {
            ScrollView {
                LazyVStack {
                    ForEach(photosAlbumsProvider.availableAlbums) { album in
                        Button {
                            // TODO: Fetch Photos from album
                            
                        } label: {
                            HStack {
                                AsyncImage(url: album.coverPhotoBaseUrl, content: { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 65, height: 65)
                                        .clipShape(Rectangle())
                                }, placeholder: {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 65, height: 65)
                                        .clipShape(Rectangle())
                                })
                                .padding(.all)
                                Text(album.title)
                                Spacer()
                            }
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.all)
                            .shadow(radius: 5, x: 2.5, y: 2.5)
                        }

                    }
                }
            }
        } else {
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
    }
    
    func signInAndConsentAction() {
        Task(priority: .userInitiated) {
            let didUserSignIn: Bool
            do {
                didUserSignIn = try await GooglePhotoAlbumsProvider.shared.askForUserSignIn()
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
                didUserConsent = try await GooglePhotoAlbumsProvider.shared.askForUsersConsent()
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
