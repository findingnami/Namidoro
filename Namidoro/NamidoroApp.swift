//
//  NamidoroApp.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

import SwiftUI
import UserNotifications
import AppKit

/* @main
struct NamidoroApp: App {
    @StateObject private var timerVM = TimerViewModel(startTime: 2 * 60) // change to 25 * 60 once done testing
    @State private var overlayWindow: NSWindow? = nil

    init() {
            // 🔔 Ask for notification permission once
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Notification permission error: \(error)")
                } else {
                    print("Notification permission granted: \(granted)")
                }
            }
        
        // ✅ Move observer setup to a static helper
               NamidoroApp.setupObservers()
        }
    
    var body: some Scene {
        MenuBarExtra(isInserted: .constant(true)) {
            // Popover content
            if timerVM.mode == .work {
                            WorkModeView(timerVM: timerVM)
                        } else {
                            BreakModeView(timerVM: timerVM)
                        }
        } label: {
            // Label with icon on left, dynamic minutes on right
            HStack(spacing: 4) {
                Image(systemName: "n.circle")
                Text("\(timerVM.timeRemaining / 60)m")
            }
        }
        
        // 🔹 Full-screen window appears in break mode
                WindowGroup {
                    if timerVM.mode == .breakTime {
                        FullScreenBreakView(timerVM: timerVM)
                            .ignoresSafeArea()
                    } else {
                        EmptyView()
                    }
                }
                .windowStyle(.hiddenTitleBar)
                .windowResizability(.contentSize)
    }
    
    // MARK: - Overlay control
        private func showFullScreenOverlay() {
            // Don't recreate if already shown
            if overlayWindow != nil { return }

            guard let screenFrame = NSScreen.main?.frame else { return }

            let window = NSWindow(
                contentRect: screenFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .mainMenu + 1        // appears above normal windows
            window.collectionBehavior = [
                .canJoinAllSpaces,              // available on all spaces
                .fullScreenAuxiliary
            ]
            window.ignoresMouseEvents = false   // keep interactive
            window.makeKeyAndOrderFront(nil)

            // host your SwiftUI view
            let hosting = NSHostingView(rootView: FullScreenBreakView(timerVM: timerVM))
            hosting.frame = screenFrame
            hosting.autoresizingMask = [.width, .height]
            window.contentView = hosting

            overlayWindow = window
        }

        private func hideFullScreenOverlay() {
            overlayWindow?.orderOut(nil)
            overlayWindow = nil
        }
    
    // MARK: - Static helper to handle notifications
        private static func setupObservers() {
            NotificationCenter.default.addObserver(
                forName: .didEnterBreakMode,
                object: nil,
                queue: .main
            ) { _ in
                // Call the global app instance to show overlay
                if let app = NSApp.delegate as? AppDelegateProtocol {
                    app.showBreakOverlay()
                }
            }

            NotificationCenter.default.addObserver(
                forName: .didExitBreakMode,
                object: nil,
                queue: .main
            ) { _ in
                if let app = NSApp.delegate as? AppDelegateProtocol {
                    app.hideBreakOverlay()
                }
            }
        }
}

protocol AppDelegateProtocol {
    func showBreakOverlay()
    func hideBreakOverlay()
}

extension NamidoroApp: AppDelegateProtocol {
    func showBreakOverlay() {
        showFullScreenOverlay()
    }

    func hideBreakOverlay() {
        hideFullScreenOverlay()
    }
}

*/


import SwiftUI
import UserNotifications

@main
struct NamidoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerVM = TimerViewModel(startTime: 2 * 60)

    init() {
        // Link timerVM to AppDelegate
        //        appDelegate.timerVM = timerVM
        
        // Ask for notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }

    var body: some Scene {
            MenuBarExtra(isInserted: .constant(true)) {
                // Popover content — attach onAppear HERE ✅
                Group {
                    if timerVM.mode == .work {
                        WorkModeView(timerVM: timerVM)
                    } else {
                        BreakModeView(timerVM: timerVM)
                    }
                }
                .onAppear {
                    appDelegate.timerVM = timerVM
                    print("✅ Linked timerVM to AppDelegate")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "n.circle")
                    Text("\(timerVM.timeRemaining / 60)m")
                }
            }
        }
}
