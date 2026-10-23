//
//  TimerViewModelTests.swift
//  NamidoroTests
//

import Testing
import Foundation
import AppKit
@testable import Namidoro

// Serialized: tests share TimerViewModel's static audio-player registry and NSWorkspace's
// single process-wide notification center, both mutated by real Timer callbacks running on
// RunLoop.main — running them concurrently (Swift Testing's default) raced and crashed the
// test runner.
@Suite(.serialized)
struct TimerViewModelTests {

    // Each test gets its own UserDefaults suite so settings changes in one test can't leak
    // into another (SettingsStore() with no arguments reads/writes UserDefaults.standard).
    private func makeSettingsStore(workMinutes: Int = 25, breakMinutes: Int = 5) -> SettingsStore {
        let defaults = UserDefaults(suiteName: "namidoro-tests-\(UUID().uuidString)")!
        let store = SettingsStore(defaults: defaults)
        store.workMinutes = workMinutes
        store.breakMinutes = breakMinutes
        return store
    }

    @Test func countsDownFromFakeClock() async throws {
        var currentDate = Date(timeIntervalSince1970: 1000)
        let vm = TimerViewModel(startTime: 100, settingsStore: makeSettingsStore(), now: { currentDate })
        vm.start()
        #expect(vm.timeRemaining == 100)

        currentDate = currentDate.addingTimeInterval(30)
        vm.tick()
        #expect(vm.timeRemaining == 70)

        currentDate = currentDate.addingTimeInterval(69)
        vm.tick()
        #expect(vm.timeRemaining == 1)

        vm.stop()
    }

    @Test func pauseAndResumePreserveRemaining() async throws {
        var currentDate = Date(timeIntervalSince1970: 0)
        let vm = TimerViewModel(startTime: 100, settingsStore: makeSettingsStore(), now: { currentDate })
        vm.start()

        currentDate = currentDate.addingTimeInterval(40)
        vm.pause()
        #expect(vm.timeRemaining == 60)
        #expect(vm.isRunning == false)

        // Wall clock keeps moving while paused — must not be consumed.
        currentDate = currentDate.addingTimeInterval(500)
        #expect(vm.timeRemaining == 60)

        vm.start()
        currentDate = currentDate.addingTimeInterval(10)
        vm.tick()
        #expect(vm.timeRemaining == 50)

        vm.stop()
    }

    @Test func sleepAndWakeDoesNotConsumeTimeOrSwitchModes() async throws {
        var currentDate = Date(timeIntervalSince1970: 0)
        let vm = TimerViewModel(startTime: 50, settingsStore: makeSettingsStore(), now: { currentDate })
        vm.start()

        currentDate = currentDate.addingTimeInterval(40)
        vm.tick()
        #expect(vm.timeRemaining == 10)

        let center = NSWorkspace.shared.notificationCenter
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        #expect(vm.isRunning == false)

        // Mac stays asleep for an hour — the real wall clock keeps moving underneath us.
        currentDate = currentDate.addingTimeInterval(3600)

        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        #expect(vm.isRunning == true)
        #expect(vm.mode == .work)
        #expect(vm.timeRemaining == 10)

        vm.stop()
    }

    @Test func workSessionEndTransitionsToBreakMode() async throws {
        var currentDate = Date(timeIntervalSince1970: 0)
        let settingsStore = makeSettingsStore(breakMinutes: 1)
        let vm = TimerViewModel(startTime: 50, settingsStore: settingsStore, now: { currentDate })
        vm.start()

        currentDate = currentDate.addingTimeInterval(50)
        vm.tick()

        #expect(vm.mode == .breakTime)
        #expect(vm.timeRemaining == settingsStore.breakMinutes * 60)
        #expect(vm.isRunning == true)

        vm.stop()
    }

    @Test func breakSessionEndTransitionsToWorkMode() async throws {
        var currentDate = Date(timeIntervalSince1970: 0)
        let settingsStore = makeSettingsStore(workMinutes: 2, breakMinutes: 1)
        let vm = TimerViewModel(startTime: settingsStore.breakMinutes * 60, settingsStore: settingsStore, now: { currentDate })
        vm.mode = .breakTime
        vm.start()

        currentDate = currentDate.addingTimeInterval(TimeInterval(settingsStore.breakMinutes * 60))
        vm.tick()

        #expect(vm.mode == .work)
        #expect(vm.timeRemaining == settingsStore.workMinutes * 60)
        #expect(vm.isRunning == true)

        vm.stop()
    }

    @Test func oneMinuteWarningFiresExactlyOnceForLongSession() async throws {
        var currentDate = Date(timeIntervalSince1970: 0)
        let vm = TimerViewModel(startTime: 70, settingsStore: makeSettingsStore(), now: { currentDate })
        vm.start()
        #expect(vm.hasTriggeredOneMinuteWarning == false)

        currentDate = currentDate.addingTimeInterval(11) // remaining = 59
        vm.tick()
        #expect(vm.timeRemaining == 59)
        #expect(vm.hasTriggeredOneMinuteWarning == true)

        // Keep ticking — the flag must not re-trigger or flip back.
        currentDate = currentDate.addingTimeInterval(5)
        vm.tick()
        #expect(vm.hasTriggeredOneMinuteWarning == true)

        vm.stop()
    }

    @Test func oneMinuteWarningDoesNotFireForShortSession() async throws {
        var currentDate = Date(timeIntervalSince1970: 0)
        let vm = TimerViewModel(startTime: 50, settingsStore: makeSettingsStore(), now: { currentDate })
        vm.start()

        currentDate = currentDate.addingTimeInterval(45)
        vm.tick()
        #expect(vm.timeRemaining == 5)
        #expect(vm.hasTriggeredOneMinuteWarning == false)

        vm.stop()
    }

    @Test func oneMinuteWarningDoesNotFireInBreakMode() async throws {
        var currentDate = Date(timeIntervalSince1970: 0)
        let settingsStore = makeSettingsStore(breakMinutes: 1)
        let vm = TimerViewModel(startTime: settingsStore.breakMinutes * 60, settingsStore: settingsStore, now: { currentDate })
        vm.mode = .breakTime
        vm.start()

        currentDate = currentDate.addingTimeInterval(TimeInterval(settingsStore.breakMinutes * 60 - 5))
        vm.tick()
        #expect(vm.hasTriggeredOneMinuteWarning == false)

        vm.stop()
    }

    @Test func oneMinuteWarningDoesNotFireWhenDisabledInSettings() async throws {
        var currentDate = Date(timeIntervalSince1970: 0)
        let settingsStore = makeSettingsStore()
        settingsStore.oneMinuteWarningEnabled = false
        let vm = TimerViewModel(startTime: 70, settingsStore: settingsStore, now: { currentDate })
        vm.start()

        currentDate = currentDate.addingTimeInterval(11) // remaining = 59
        vm.tick()
        #expect(vm.hasTriggeredOneMinuteWarning == false)

        vm.stop()
    }
}
