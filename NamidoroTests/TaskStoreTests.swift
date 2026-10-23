//
//  TaskStoreTests.swift
//  NamidoroTests
//

import Testing
import Foundation
@testable import Namidoro

struct TaskStoreTests {

    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("tasks.json")
    }

    @Test func emptyTitleIsRejected() async throws {
        let store = TaskStore(fileURL: tempFileURL())
        store.add(title: "")
        #expect(store.tasks.isEmpty)
    }

    @Test func whitespaceOnlyTitleIsRejected() async throws {
        let store = TaskStore(fileURL: tempFileURL())
        store.add(title: "   \n  ")
        #expect(store.tasks.isEmpty)
    }

    @Test func selectTogglesSelection() async throws {
        let store = TaskStore(fileURL: tempFileURL())
        store.add(title: "Write tests")
        let task = try #require(store.tasks.first)

        store.select(task)
        #expect(store.selectedTaskID == task.id)

        store.select(task)
        #expect(store.selectedTaskID == nil)
    }

    @Test func markingSelectedTaskDoneDeselectsIt() async throws {
        let store = TaskStore(fileURL: tempFileURL())
        store.add(title: "Write tests")
        let task = try #require(store.tasks.first)

        store.select(task)
        #expect(store.selectedTaskID == task.id)

        store.toggleDone(task)
        #expect(store.selectedTaskID == nil)
        #expect(store.tasks.first?.isDone == true)
    }

    @Test func deletingSelectedTaskDeselectsIt() async throws {
        let store = TaskStore(fileURL: tempFileURL())
        store.add(title: "Write tests")
        let task = try #require(store.tasks.first)

        store.select(task)
        store.delete(task)

        #expect(store.selectedTaskID == nil)
        #expect(store.tasks.isEmpty)
    }

    @Test func persistenceRoundTripsThroughFile() async throws {
        let url = tempFileURL()

        let store1 = TaskStore(fileURL: url)
        store1.add(title: "Task one")
        store1.add(title: "Task two")
        let firstTask = try #require(store1.tasks.first)
        store1.select(firstTask)

        let store2 = TaskStore(fileURL: url)
        #expect(store2.tasks == store1.tasks)
        #expect(store2.selectedTaskID == store1.selectedTaskID)
    }

    @Test func corruptFileYieldsEmptyStore() async throws {
        let url = tempFileURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not valid json".utf8).write(to: url)

        let store = TaskStore(fileURL: url)
        #expect(store.tasks.isEmpty)
        #expect(store.selectedTaskID == nil)
    }
}
