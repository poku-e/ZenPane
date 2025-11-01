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

    var body: some Scene {
        Settings { EmptyView() } // Prevents default SwiftUI window
    }
}
