//
//  ZenpaneApp.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

import SwiftUI

@main
struct ZenpaneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        Settings {
            PreferencesView()
                .environmentObject(settings)
                .preferredColorScheme(settings.preferredAppearance.colorScheme)
        }
    }
}
