//
//  AppleDelegate.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/7/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate? = nil
    var overlayWindow: NSWindow?
    var timerVM: TimerViewModel?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .didEnterBreakMode,
            object: nil,
            queue: .main
        ) { _ in
            AppDelegate.shared?.showBreakOverlay()
        }

        NotificationCenter.default.addObserver(
            forName: .didExitBreakMode,
            object: nil,
            queue: .main
        ) { _ in
            AppDelegate.shared?.hideBreakOverlay()
        }
    }

    // MARK: - Overlay Management

    func showBreakOverlay() {
        guard overlayWindow == nil,
              let screenFrame = NSScreen.main?.frame,
              let timerVM = timerVM else { return }

        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.alphaValue = 0  // Start transparent
        window.level = .mainMenu + 1
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false

       // let hostingView = NSHostingView(rootView: FullScreenBreakView(timerVM: timerVM))
        let rootView = FullScreenBreakView()
            .environmentObject(timerVM) // ✅ attach the environment object here
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = screenFrame
        window.contentView = hostingView
        hostingView.frame = screenFrame
        window.contentView = hostingView

        window.makeKeyAndOrderFront(nil)
        overlayWindow = window

        // ✅ Fade in animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            window.animator().alphaValue = 1.0
        }
    }

    func hideBreakOverlay() {
        guard let window = overlayWindow else { return }

        // ✅ Fade out animation before closing
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            self.overlayWindow = nil
        })
    }
}
