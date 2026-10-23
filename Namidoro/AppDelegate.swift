//
//  AppDelegate.swift
//  Namidoro
//
//  Created by Maria Rachel on 10/7/25.
//

import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static var shared: AppDelegate? = nil
    var overlayWindows: [NSWindow] = []
    private var isBreakActive = false
    private var screenParamsObserver: NSObjectProtocol?

    // Handed over once from NamidoroApp.body (not NamidoroApp.init() — AppDelegate.shared isn't
    // guaranteed set yet at that point) so the menu and the break overlay always share the same
    // TimerViewModel instance instead of each ending up with their own.
    var timerVM: TimerViewModel?

    private var outsideClickMonitors: [Any] = []

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set notification delegate to show notifications even when app is active
        UNUserNotificationCenter.current().delegate = self
        setupObservers()
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .didEnterBreakMode,
            object: nil,
            queue: .main
        ) { notification in
            // The popover must close the moment a break starts, not just when the overlay appears.
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

        // A .window-style MenuBarExtra popover is documented to dismiss on outside click, but
        // that relies on the app running as an accessory app (LSUIElement = true). This target's
        // build settings leave INFOPLIST_KEY_LSUIElement unset, so the app runs with a regular
        // activation policy and the popover never resigns key on an outside click. That's a
        // build setting inside the .xcodeproj, which is off-limits here, so we detect the
        // popover opening/closing ourselves and enforce outside-click dismissal manually instead.
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

    // MARK: - MenuBarExtra popover window management

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
                    // While typing in the task field, the field editor (an NSTextView) is
                    // firstResponder — let Escape pass through to it instead of closing the
                    // popover out from under the user mid-edit.
                    let isEditingText = window.firstResponder is NSTextView
                    if !isEditingText {
                        AppDelegate.closeMenuBarExtraPopover()
                    }
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
        isBreakActive = true
        observeScreenParameterChanges(timerVM: timerVM)

        if !overlayWindows.isEmpty {
            // Windows already exist — they may be mid fade-out from hideBreakOverlay().
            // Fade them back in instead of bailing out, so a break that starts during that
            // 0.5s window still shows the overlay.
            for window in overlayWindows {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.5
                    window.animator().alphaValue = 1.0
                }
            }
            return
        }

        overlayWindows = NSScreen.screens.map { makeOverlayWindow(for: $0, timerVM: timerVM) }
        for window in overlayWindows {
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                window.animator().alphaValue = 1.0
            }
        }
    }

    func hideBreakOverlay() {
        isBreakActive = false
        if let screenParamsObserver {
            NotificationCenter.default.removeObserver(screenParamsObserver)
            self.screenParamsObserver = nil
        }

        let windowsToClose = overlayWindows
        guard !windowsToClose.isEmpty else { return }

        // Fade out animation before closing
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            windowsToClose.forEach { $0.animator().alphaValue = 0 }
        }, completionHandler: { [weak self] in
            guard let self else { return }
            for window in windowsToClose {
                // If a new break started during the fade-out, showBreakOverlay already
                // animated this same window's alpha back up — don't tear it down then.
                guard window.alphaValue == 0 else { continue }
                window.orderOut(nil)
                self.overlayWindows.removeAll { $0 === window }
            }
        })
    }

    private func makeOverlayWindow(for screen: NSScreen, timerVM: TimerViewModel) -> NSWindow {
        let window = BreakOverlayWindow(
            contentRect: screen.frame,
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
        window.onEscape = { [weak timerVM] in
            timerVM?.switchToWorkMode()
        }

        let rootView = FullScreenBreakView()
            .environmentObject(timerVM)
        let hostingView = NSHostingView(rootView: rootView)
        // Window-relative, NOT screen.frame — a secondary display's frame has a non-zero
        // origin in the global coordinate space, and using that directly here would push
        // the content outside the window's own (0,0)-based bounds.
        hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)
        window.contentView = hostingView

        return window
    }

    // Monitor plugged/unplugged while a break is active — rebuild the window set to match
    // the new NSScreen.screens instead of leaving stale windows positioned for displays that
    // no longer exist (or missing ones for newly-connected displays).
    private func observeScreenParameterChanges(timerVM: TimerViewModel) {
        guard screenParamsObserver == nil else { return }
        screenParamsObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak timerVM] _ in
            guard let self, self.isBreakActive, let timerVM else { return }
            let oldWindows = self.overlayWindows
            self.overlayWindows = NSScreen.screens.map { self.makeOverlayWindow(for: $0, timerVM: timerVM) }
            for window in self.overlayWindows {
                window.alphaValue = 1.0
                window.makeKeyAndOrderFront(nil)
            }
            oldWindows.forEach { $0.orderOut(nil) }
        }
    }
}
