//
//  TaskListView.swift
//  Namidoro
//

import SwiftUI

// A row for a single task: checkbox to toggle done, title to select, and a
// delete button that only appears on hover — mirrors MenuRow's hover style.
struct TaskRowView: View {
    let task: TaskItem
    @EnvironmentObject var taskStore: TaskStore

    @State private var isHovering = false

    private var isSelected: Bool {
        taskStore.selectedTaskID == task.id
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                taskStore.toggleDone(task)
            } label: {
                Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)

            Text(task.title)
                .strikethrough(task.isDone)
                .foregroundStyle(isHovering ? Color.white : (task.isDone ? Color.secondary : Color.primary))
                .opacity(task.isDone ? 0.6 : 1.0)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(isHovering ? Color.white : Color.accentColor)
            }

            if isHovering {
                Button {
                    taskStore.delete(task)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(isHovering ? Color.white : Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.accentColor.opacity(0.85) : (isSelected ? Color.accentColor.opacity(0.15) : Color.clear))
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            guard !task.isDone else { return }
            taskStore.select(task)
        }
    }
}

// The task section shown under the time display in WorkModeView: a capped-height
// scrollable list (open tasks above done tasks), an add field, and a "Clear completed"
// row. None of these actions close the popover.
struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var newTaskTitle = ""

    // A .window-style MenuBarExtra popover sizes itself to fit its content, and ScrollView
    // has no intrinsic height of its own — a bare .frame(maxHeight:) with no floor lets it
    // collapse to zero. Deriving an explicit height from the row count (capped at ~150pt)
    // sidesteps that instead of relying on the ScrollView's own size negotiation.
    private let rowHeight: CGFloat = 26

    private var openTasks: [TaskItem] {
        taskStore.tasks.filter { !$0.isDone }
    }

    private var doneTasks: [TaskItem] {
        taskStore.tasks.filter { $0.isDone }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !taskStore.tasks.isEmpty {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(openTasks) { task in
                            TaskRowView(task: task)
                        }
                        ForEach(doneTasks) { task in
                            TaskRowView(task: task)
                        }
                    }
                }
                .frame(height: min(CGFloat(taskStore.tasks.count) * rowHeight, 150))
            }

            TextField("Add a task…", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    taskStore.add(title: newTaskTitle)
                    newTaskTitle = ""
                }

            if !doneTasks.isEmpty {
                MenuRow(title: "Clear completed") {
                    taskStore.clearCompleted()
                }
            }
        }
        .padding(.vertical, 4)
    }
}
