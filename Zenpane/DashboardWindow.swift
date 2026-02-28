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
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1440, height: 900)
        let windowSize = CGSize(width: 1080, height: 720)
        let frame = CGRect(
            x: (screenSize.width - windowSize.width) / 2,
            y: (screenSize.height - windowSize.height) / 2,
            width: windowSize.width,
            height: windowSize.height
        )

        super.init(contentRect: frame,
                   styleMask: [.titled, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)

        isOpaque = false
        backgroundColor = .clear
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hasShadow = true
        level = .floating
        isMovableByWindowBackground = true

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
}
