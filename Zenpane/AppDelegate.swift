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
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        dashboardWindow = DashboardWindow()
        dashboardWindow?.showDashboard()
        configureStatusItem()
        print("Zenpane launched")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    @objc private func toggleDashboard(_ sender: Any?) {
        dashboardWindow?.toggleVisibility()
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "Zenpane"
        item.button?.toolTip = "Zenpane Dashboard"

        let menu = NSMenu()
        menu.addItem(
            withTitle: "Toggle Dashboard",
            action: #selector(toggleDashboard(_:)),
            keyEquivalent: "z"
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )

        item.menu = menu
        statusItem = item
    }
}
