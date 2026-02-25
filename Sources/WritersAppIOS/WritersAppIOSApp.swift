// WritersAppIOSApp.swift
//
// Entry point for the iOS app.
// To build an IPA:
//   1. Open Package.swift in Xcode (File > Open > select Package.swift)
//   2. Select the "WritersAppIOS" scheme and an iOS device/simulator
//   3. Product > Archive
//   4. Distribute App from the Organizer

import SwiftUI

@main
struct WritersAppIOSApp: App {

    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
