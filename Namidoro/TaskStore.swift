//
//  TaskStore.swift
//  Namidoro
//

import Foundation
import os

class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var selectedTaskID: UUID?

    private let fileURL: URL

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Namidoro", category: "TaskStore")

    private struct PersistedState: Codable {
        var tasks: [TaskItem]
        var selectedTaskID: UUID?
    }

    static func defaultFileURL() -> URL {
        let bundleID = Bundle.main.bundleIdentifier ?? "Namidoro"
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent("tasks.json")
    }

    init(fileURL: URL = TaskStore.defaultFileURL()) {
        self.fileURL = fileURL
        load()
    }

    var selectedTask: TaskItem? {
        guard let selectedTaskID else { return nil }
        return tasks.first { $0.id == selectedTaskID }
    }

    // MARK: - Mutations

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(TaskItem(title: trimmed))
        save()
    }

    func toggleDone(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()
        if tasks[index].isDone, selectedTaskID == task.id {
            selectedTaskID = nil
        }
        save()
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        if selectedTaskID == task.id {
            selectedTaskID = nil
        }
        save()
    }

    func select(_ task: TaskItem) {
        selectedTaskID = (selectedTaskID == task.id) ? nil : task.id
        save()
    }

    func clearCompleted() {
        if let selectedTaskID, tasks.first(where: { $0.id == selectedTaskID })?.isDone == true {
            self.selectedTaskID = nil
        }
        tasks.removeAll { $0.isDone }
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // Nothing persisted yet — expected on first launch, not an error.
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let state = try JSONDecoder().decode(PersistedState.self, from: data)
            tasks = state.tasks
            selectedTaskID = state.selectedTaskID
        } catch {
            Self.logger.error("Failed to load tasks from \(self.fileURL.path, privacy: .public): \(String(describing: error), privacy: .public)")
            tasks = []
            selectedTaskID = nil
        }
    }

    private func save() {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let state = PersistedState(tasks: tasks, selectedTaskID: selectedTaskID)
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Self.logger.error("Failed to save tasks to \(self.fileURL.path, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }
}
