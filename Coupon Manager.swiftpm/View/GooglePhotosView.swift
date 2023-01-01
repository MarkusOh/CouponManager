//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/26.
//

import SwiftUI

struct GooglePhotosView: View {
    @ObservedObject var photosProvider = GooglePhotosDataProvider.shared
    
    @State private var errorMessage = ErrorMessage.empty
    @State private var isShowingError = false
    
    @Binding var isPresented: Bool
    @Binding var selectedPhoto: UIImage?
    
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

struct GooglePhotosPicker: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedPhoto: UIImage?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, content: {
                GooglePhotosView(isPresented: $isPresented, selectedPhoto: $selectedPhoto)
            })
    }
}

extension View {
    func googlePhotosPicker(isPresented: Binding<Bool>, selectedPhoto: Binding<UIImage?>) -> some View {
        self.modifier(GooglePhotosPicker(isPresented: isPresented, selectedPhoto: selectedPhoto))
    }
}

struct GooglePhotosView_Previews: PreviewProvider {
    @State static var isPresented = true
    @State static var selectedPhoto: UIImage?
    
    static var previews: some View {
        GooglePhotosView(isPresented: $isPresented, selectedPhoto: $selectedPhoto)
    }
}
