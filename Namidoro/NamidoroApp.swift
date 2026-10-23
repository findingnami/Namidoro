//
//  NamidoroApp.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

import SwiftUI
import UserNotifications
import AppKit

@main
struct NamidoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timerVM = TimerViewModel(startTime: TimerViewModel.workDuration)
    @StateObject private var taskStore = TaskStore()

    init() {
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
        // Hand the one @StateObject instance to AppDelegate here, in body — not in init().
        // Reading a @StateObject's wrappedValue manually inside init() bypasses SwiftUI's
        // identity-preserving storage and evaluates its default-value expression again,
        // producing a throwaway TimerViewModel (with its own live Timer) every time. That's what
        // caused the menu and the break overlay to end up driven by two different instances.
        // body is evaluated once SwiftUI has fully installed both appDelegate and timerVM, so
        // this assignment (guarded to only run once) is the single place the timer is started.
        // start() mutates @Published isRunning, so it's dispatched to the next run loop tick —
        // calling it synchronously here trips SwiftUI's "Publishing changes from within view
        // updates" fault, since body is still being evaluated at this point.
        if appDelegate.timerVM == nil {
            appDelegate.timerVM = timerVM
            DispatchQueue.main.async {
                timerVM.start()
            }
        }

        // Remove the WindowGroup/EmptyView completely — no blank window
        return MenuBarExtra(isInserted: .constant(true)) {
            // content that appears in the popover - give it the environment object
            MenuContentView()
                .environmentObject(timerVM)
                .environmentObject(taskStore)
        } label: {
            // use the @StateObject directly here so the label updates live
            HStack(spacing: 6) {
                Image(systemName: "n.circle")
                Text("\(timerVM.timeRemaining / 60)m") // minutes-only label
            }
        }
        .menuBarExtraStyle(.window)
        // also make the VM available to any SwiftUI view that uses environmentObject
        .environmentObject(timerVM)
        .environmentObject(taskStore)
    }
}
