import SwiftUI
import GoogleSignIn

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn(completion: { _, _ in
                        // Trigger Album fetching immediately
                        let _ = GooglePhotoAlbumsProvider.shared
                    })
                }
        }
    }
}
