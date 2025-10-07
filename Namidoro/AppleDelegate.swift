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

    func showBreakOverlay() {
        guard overlayWindow == nil, let screenFrame = NSScreen.main?.frame, let timerVM = timerVM else { return }

        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .mainMenu + 1
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false

        let hostingView = NSHostingView(rootView: FullScreenBreakView(timerVM: timerVM))
        hostingView.frame = screenFrame
        window.contentView = hostingView

        window.makeKeyAndOrderFront(nil)
        overlayWindow = window
    }

    func hideBreakOverlay() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}
