//
//  AppDelegate.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var dashboardWindow: DashboardWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        dashboardWindow = DashboardWindow()
        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        print("Zenpane launched")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }
}
