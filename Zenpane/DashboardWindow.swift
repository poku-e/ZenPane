//
//  DashboardWindow.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

//
//  DashboardWindow.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

import Cocoa
import SwiftUI

class DashboardWindow: NSWindow {
    init() {
        let hostingView = NSHostingView(rootView: DashboardView())
        let screenFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let windowSize = CGSize(
            width: min(1440, screenFrame.width * 0.92),
            height: min(900, screenFrame.height * 0.92)
        )
        let frame = CGRect(
            x: screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2,
            y: screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2,
            width: windowSize.width,
            height: windowSize.height
        )

        super.init(contentRect: frame,
                   styleMask: [.titled, .fullSizeContentView, .resizable],
                   backing: .buffered,
                   defer: false)

        isOpaque = false
        backgroundColor = .clear
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = true
        minSize = CGSize(width: 1100, height: 760)

        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 24
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.shadowOpacity = 0.25
        hostingView.layer?.shadowRadius = 20
        self.contentView = hostingView

        DispatchQueue.main.async {
            self.alphaValue = 0
            self.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 1.0
                self.animator().alphaValue = 1.0
            }
        }
    }

    func toggleVisibility() {
        if isVisible {
            orderOut(nil)
        } else {
            showDashboard()
        }
    }
    func showDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }
}
