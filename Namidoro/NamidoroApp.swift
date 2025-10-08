//
//  NamidoroApp.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

/*import SwiftUI
import UserNotifications
import AppKit

@main
struct NamidoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerVM = TimerViewModel(startTime: 2 * 60) // 25 * 60

    init() {
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
                       // WorkModeView(timerVM: timerVM)
                        WorkModeView()
                    } else {
                       // BreakModeView(timerVM: timerVM)
                        BreakModeView()
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
            .environmentObject(timerVM)
        }
}
*/

import SwiftUI
import UserNotifications
import AppKit

@main
struct NamidoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerVM = TimerViewModel(startTime: 2 * 60) // testing value

    init() {
        // give AppDelegate the VM immediately so overlay creation never sees nil
        appDelegate.timerVM = timerVM
        print("NamidoroApp.init: linked timerVM to appDelegate")

        // ask for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }

    var body: some Scene {
        // Remove the WindowGroup/EmptyView completely — no blank window
        MenuBarExtra(isInserted: .constant(true)) {
            // content that appears in the popover - give it the environment object
            MenuContentView()
                .environmentObject(timerVM)
        } label: {
            // use the @StateObject directly here so the label updates live
            HStack(spacing: 6) {
                Image(systemName: "n.circle")
                Text("\(timerVM.timeRemaining / 60)m") // minutes-only label
            }
        }
        // also make the VM available to any SwiftUI view that uses environmentObject
        .environmentObject(timerVM)
    }
}
