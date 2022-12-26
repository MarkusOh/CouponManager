//
//  File.swift
//  
//
//  Created by Seungsub Oh on 2022/12/26.
//

import UIKit
import Combine
import GoogleSignIn

enum GooglePhotoAlbumsProviderError: Error {
    case userDidNotSignIn
    case userDidNotConsent
    case rootViewControllerUnavailable
    case unableToFetchAccessToken
    case unsuccessfulResponseCode
}

class GooglePhotoAlbumsProvider: ObservableObject {
    static let shared = GooglePhotoAlbumsProvider()
    
    @Published var availableAlbums: [GooglePhotosAlbum] = []
    @Published var isGooglePhotosAvailable: Bool = (GIDSignIn.sharedInstance.currentUser?.grantedScopes ?? []).contains(GooglePhotoAlbumsProvider.photosScope)
    @Published var errorReminder: Error? = nil
    
    static let googlePhotosAPIKey = "AIzaSyCXrm2FEm0AZtCvbkNaRtuK1sPgMO1SDIk"
    static let photosScope = "https://www.googleapis.com/auth/photoslibrary.readonly"
    
    init() {
        Task {
            let googleSignInChange =
                GIDSignIn.sharedInstance.publisher(for: \.currentUser)
                    .first(where: { $0 != nil })
                    .flatMap { _ in
                        return Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
                    }
                    .first(where: { _ in
                        (GIDSignIn.sharedInstance.currentUser!.grantedScopes ?? []).contains(GooglePhotoAlbumsProvider.photosScope)
                    })
            
            for await _ in googleSignInChange.values {
                do {
                    await MainActor.run { [unowned self] in
                        if isGooglePhotosAvailable != true {
                            isGooglePhotosAvailable = true
                        }
                    }
                    try await attempFetchingAlbums()
                } catch {
                    errorReminder = error
                }
            }
        }
    }
    
    var rootViewController: UIViewController? {
        guard let window = UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }).compactMap({ $0 }).map({ $0.windows }).flatMap({ $0 }).filter({ $0.isKeyWindow }).first else {
            return nil
        }
        
        return window.rootViewController
    }
    
    func attempFetchingAlbums() async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GooglePhotoAlbumsProviderError.userDidNotSignIn
        }
        
        guard (user.grantedScopes ?? []).contains(GooglePhotoAlbumsProvider.photosScope) else {
            throw GooglePhotoAlbumsProviderError.userDidNotConsent
        }
        
        let accessToken = try await getAccessTokenFromUser()
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "photoslibrary.googleapis.com"
        components.path = "/v1/albums"
        components.queryItems = [
            URLQueryItem(name: "key", value: GooglePhotoAlbumsProvider.googlePhotosAPIKey)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession(configuration: .default).data(for: request)
        let responseCode = (response as! HTTPURLResponse).statusCode
        
        guard (200..<300).contains(responseCode) else {
            throw GooglePhotoAlbumsProviderError.unsuccessfulResponseCode
        }
        
        let receivedData = try JSONDecoder().decode(GooglePhotosAlbumsStructure.self, from: data)
        
        await MainActor.run(body: {
            availableAlbums = receivedData.albums.sorted(by: { $0.title < $1.title })
        })
    }
    
    func getAccessTokenFromUser() async throws -> String {
        return try await withCheckedThrowingContinuation({ continuation in
            GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded(completion: { user, error in
                guard error == nil,
                      let user = user else {
                    continuation.resume(throwing: GooglePhotoAlbumsProviderError.unableToFetchAccessToken)
                    return
                }
                
                continuation.resume(returning: user.accessToken.tokenString)
            })
        })
    }
    
    @MainActor
    func askForUserSignIn() async throws -> Bool {
        guard let rootViewController = rootViewController else {
            throw GooglePhotoAlbumsProviderError.rootViewControllerUnavailable
        }
        
        // If user already signed in
        guard GIDSignIn.sharedInstance.currentUser == nil else { return true }
        
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                guard result != nil && error == nil else {
                    continuation.resume(returning: false)
                    return
                }
                
                continuation.resume(returning: true)
            }
        }
    }
    
    @MainActor
    func askForUsersConsent() async throws -> Bool {
        guard let rootViewController = rootViewController else {
            throw GooglePhotoAlbumsProviderError.rootViewControllerUnavailable
        }
        
        let userGrantedScopes = GIDSignIn.sharedInstance.currentUser?.grantedScopes ?? []
        
        guard !userGrantedScopes.contains(GooglePhotoAlbumsProvider.photosScope) else {
            return true
        }
        
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.currentUser?.addScopes([GooglePhotoAlbumsProvider.photosScope], presenting: rootViewController) { result, error in
                guard let result = result,
                      error == nil else {
                    continuation.resume(returning: false)
                    return
                }
                
                guard let scope = result.user.grantedScopes,
                      scope.contains(GooglePhotoAlbumsProvider.photosScope) else {
                    continuation.resume(returning: false)
                    return
                }
                
                continuation.resume(returning: true)
            }
        }
    }
}
