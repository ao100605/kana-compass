//
//  Kana_CompassApp.swift
//  Kana Compass
//
//  Created by Akari Oh on 8/28/2026.
//

import SwiftUI

@main
struct Kana_CompassApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

private struct RootView: View {
    @State private var isLoading = true
    @State private var hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
                    .transition(.opacity)
            } else if !hasSeenWelcome {
                WelcomeView {
                    UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasSeenWelcome = true
                    }
                }
                .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            isLoading = false
        }
    }
}
