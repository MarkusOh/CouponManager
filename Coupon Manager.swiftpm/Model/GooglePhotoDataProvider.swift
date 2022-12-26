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

class GooglePhotosDataProvider: ObservableObject {
    static let shared = GooglePhotosDataProvider()
    
    @Published var availablePhotos: [GooglePhotoItem] = []
    @Published var isGooglePhotosAvailable: Bool = (GIDSignIn.sharedInstance.currentUser?.grantedScopes ?? []).contains(GooglePhotosDataProvider.photosScope)
    @Published var errorReminder: Error? = nil
    
    static let googlePhotosAPIKey = "AIzaSyCXrm2FEm0AZtCvbkNaRtuK1sPgMO1SDIk"
    static let photosScope = "https://www.googleapis.com/auth/photoslibrary.readonly"
    
    var nextPageToken: String? = nil
    
    init() {
        Task {
            let googleSignInChange =
                GIDSignIn.sharedInstance.publisher(for: \.currentUser)
                    .first(where: { $0 != nil })
                    .flatMap { _ in
                        return Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
                    }
                    .first(where: { _ in
                        (GIDSignIn.sharedInstance.currentUser!.grantedScopes ?? []).contains(GooglePhotosDataProvider.photosScope)
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
                    await MainActor.run {
                        errorReminder = error
                    }
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
    
    func attempFetchingAlbums(nextPageToken: String? = nil) async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GooglePhotoAlbumsProviderError.userDidNotSignIn
        }
        
        guard (user.grantedScopes ?? []).contains(GooglePhotosDataProvider.photosScope) else {
            throw GooglePhotoAlbumsProviderError.userDidNotConsent
        }
        
        let accessToken = try await getAccessTokenFromUser()
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "photoslibrary.googleapis.com"
        components.path = "/v1/mediaItems:search"
        components.queryItems = [
            URLQueryItem(name: "key", value: GooglePhotosDataProvider.googlePhotosAPIKey)
        ]
        
        var filter: [String: Any] = [
            "filters": [
                "mediaTypeFilter": [
                    "mediaTypes": ["PHOTO"]
                ]
            ]
        ]
        
        if let nextPageToken = nextPageToken {
            filter["pageToken"] = nextPageToken
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: filter)
        
        let (data, response) = try await URLSession(configuration: .default).data(for: request)
        let responseCode = (response as! HTTPURLResponse).statusCode
        
        guard (200..<300).contains(responseCode) else {
            throw GooglePhotoAlbumsProviderError.unsuccessfulResponseCode
        }
        
        let receivedData = try JSONDecoder().decode(GooglePhotosStructure.self, from: data)
        self.nextPageToken = receivedData.nextPageToken
        
        await MainActor.run { [unowned self] in
            availablePhotos.append(contentsOf: receivedData.mediaItems)
        }
    }
    
    func attemptToFetchMorePhotos() {
        Task {
            do {
                try await attempFetchingAlbums(nextPageToken: nextPageToken)
            } catch {
                await MainActor.run {
                    errorReminder = error
                }
            }
        }
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
        
        guard !userGrantedScopes.contains(GooglePhotosDataProvider.photosScope) else {
            return true
        }
        
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.currentUser?.addScopes([GooglePhotosDataProvider.photosScope], presenting: rootViewController) { result, error in
                guard let result = result,
                      error == nil else {
                    continuation.resume(returning: false)
                    return
                }
                
                guard let scope = result.user.grantedScopes,
                      scope.contains(GooglePhotosDataProvider.photosScope) else {
                    continuation.resume(returning: false)
                    return
                }
                
                continuation.resume(returning: true)
            }
        }
    }
}
