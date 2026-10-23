//
//  AppDelegate.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/7/25.
//

import Cocoa
import SwiftUI
import UserNotifications
import os

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static var shared: AppDelegate? = nil
    var overlayWindow: NSWindow?

    // Handed over once from NamidoroApp.body (not NamidoroApp.init() — AppDelegate.shared isn't
    // guaranteed set yet at that point) so the menu and the break overlay always share the same
    // TimerViewModel instance instead of each ending up with their own.
    var timerVM: TimerViewModel?

    private let launchLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Namidoro", category: "audio")
    private var outsideClickMonitors: [Any] = []

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set notification delegate to show notifications even when app is active
        UNUserNotificationCenter.current().delegate = self
        setupObservers()
        logBundleResources()
        // One-shot playback test, independent of the timer's own trigger logic — if this is
        // silent too, the bug is in audio playback/bundling, not in when playSound() gets called.
        TimerViewModel.playSound(named: "Mode")
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    // MARK: - Audio diagnostics (Bug B)

    private func logBundleResources() {
        let resourcePath = Bundle.main.resourcePath ?? "<nil>"
        launchLogger.info("Bundle.main.resourcePath = \(resourcePath, privacy: .public)")

        guard let resourcePath = Bundle.main.resourcePath,
              let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) else {
            launchLogger.error("logBundleResources: could not list contents of resourcePath")
            return
        }
        let wavFiles = contents.filter { $0.lowercased().hasSuffix(".wav") }
        launchLogger.info("wav files in resourcePath: \(wavFiles, privacy: .public)")
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .didEnterBreakMode,
            object: nil,
            queue: .main
        ) { notification in
            // Bug A.1: the popover must close the moment a break starts, not just the overlay appear.
            AppDelegate.closeMenuBarExtraPopover()
            // Get timerVM from the notification object
            if let timerVM = notification.object as? TimerViewModel {
                AppDelegate.shared?.showBreakOverlay(with: timerVM)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .didExitBreakMode,
            object: nil,
            queue: .main
        ) { _ in
            AppDelegate.shared?.hideBreakOverlay()
        }

        // Bug A.2 fallback: a .window-style MenuBarExtra popover is documented to dismiss on
        // outside click, but that relies on the app running as an accessory app (LSUIElement =
        // true). This target's build settings leave INFOPLIST_KEY_LSUIElement unset, so the app
        // runs with a regular activation policy and the popover never resigns key on an outside
        // click. That's a build setting inside the .xcodeproj, which is off-limits here, so we
        // detect the popover opening/closing ourselves and enforce outside-click dismissal
        // manually instead.
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow, AppDelegate.isMenuBarExtraWindow(window) else { return }
            self?.installOutsideClickMonitors(for: window)
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow, AppDelegate.isMenuBarExtraWindow(window) else { return }
            self?.removeOutsideClickMonitors()
        }
    }

    // MARK: - MenuBarExtra popover window management (Bug A)

    private static func isMenuBarExtraWindow(_ window: NSWindow) -> Bool {
        String(describing: type(of: window)).contains("MenuBarExtraWindow")
    }

    static func findMenuBarExtraWindow() -> NSWindow? {
        NSApp.windows.first { isMenuBarExtraWindow($0) }
    }

    /// Closes the MenuBarExtra popover, if it's currently open. Safe to call unconditionally —
    /// used after every popover action (except Quit) and whenever a break starts.
    static func closeMenuBarExtraPopover() {
        guard let window = findMenuBarExtraWindow() else { return }
        window.orderOut(nil)
        AppDelegate.shared?.removeOutsideClickMonitors()
    }

    private func installOutsideClickMonitors(for window: NSWindow) {
        guard outsideClickMonitors.isEmpty else { return }

        // Global monitors only ever fire for events outside our own app's windows, so any hit
        // here is already "outside the popover" by definition.
        let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            AppDelegate.closeMenuBarExtraPopover()
        }
        if let global { outsideClickMonitors.append(global) }

        // Local monitor: catches Escape, plus clicks that land in one of our OWN other windows
        // (e.g. the full-screen break overlay) while the popover is open.
        let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { event in
            if event.type == .keyDown {
                if event.keyCode == 53 { // Escape
                    AppDelegate.closeMenuBarExtraPopover()
                }
                return event
            }
            if event.window !== window {
                AppDelegate.closeMenuBarExtraPopover()
            }
            return event
        }
        if let local { outsideClickMonitors.append(local) }
    }

    private func removeOutsideClickMonitors() {
        outsideClickMonitors.forEach { NSEvent.removeMonitor($0) }
        outsideClickMonitors.removeAll()
    }

    // MARK: - Overlay Management

    func showBreakOverlay(with timerVM: TimerViewModel) {
        guard let screenFrame = NSScreen.main?.frame else { return }

        if let window = overlayWindow {
            // A window already exists — it may be mid fade-out from hideBreakOverlay().
            // Fade it back in instead of bailing out, so a break that starts during that
            // 0.5s window still shows the overlay.
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                window.animator().alphaValue = 1.0
            }
            return
        }

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

        let rootView = FullScreenBreakView()
            .environmentObject(timerVM)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = screenFrame
        window.contentView = hostingView

        window.makeKeyAndOrderFront(nil)
        overlayWindow = window

        // Fade in animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            window.animator().alphaValue = 1.0
        }
    }

    func hideBreakOverlay() {
        guard let window = overlayWindow else { return }

        // Fade out animation before closing
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self = self, self.overlayWindow === window else { return }
            // If a new break started during the fade-out, showBreakOverlay already
            // animated this same window's alpha back up — don't tear it down then.
            guard window.alphaValue == 0 else { return }
            window.orderOut(nil)
            self.overlayWindow = nil
        })
    }
}
