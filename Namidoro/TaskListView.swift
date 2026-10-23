//
//  TaskListView.swift
//  Namidoro
//

import SwiftUI

// Material-based on macOS < 26, Liquid Glass on 26+ — the task card is the one
// place in the popover asked to show real depth, so it gets its own helper here
// rather than a one-off background() at each call site.
private extension View {
    @ViewBuilder
    func taskCardBackground() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        }
    }
}

// A row for a single task: checkbox to toggle done, title to select, and a
// delete button that only appears on hover — mirrors MenuRow's hover style.
struct TaskRowView: View {
    let task: TaskItem
    @EnvironmentObject var taskStore: TaskStore

    @State private var isHovering = false

    private var isSelected: Bool {
        taskStore.selectedTaskID == task.id
    }

    private var checkboxView: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(task.isDone ? Color.accentColor : Color.clear)
            .frame(width: 18, height: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(task.isDone ? Color.clear : Color.secondary, lineWidth: 1.5)
            )
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(task.isDone ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.15), value: task.isDone)
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    taskStore.toggleDone(task)
                }
            } label: {
                checkboxView
            }
            .buttonStyle(.plain)
            .frame(width: 22, height: 22)
            .contentShape(Rectangle())

            Text(task.title)
                .strikethrough(task.isDone)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(task.isDone ? Color.secondary : Color.primary)
                .opacity(task.isDone ? 0.6 : 1.0)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isHovering {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        taskStore.delete(task)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.16) : (isHovering ? Color.primary.opacity(0.06) : Color.clear))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Tasks")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 6) {
                if !taskStore.tasks.isEmpty {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(openTasks) { task in
                                TaskRowView(task: task)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            ForEach(doneTasks) { task in
                                TaskRowView(task: task)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .frame(height: min(CGFloat(taskStore.tasks.count) * rowHeight, 150))
                }

                addTaskField

                if !doneTasks.isEmpty {
                    MenuRow(title: "Clear completed") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            taskStore.clearCompleted()
                        }
                    }
                }
            }
            .padding(10)
            .taskCardBackground()
        }
    }

    private var addTaskField: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.secondary)
            TextField("Add a task…", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .onSubmit {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        taskStore.add(title: newTaskTitle)
                    }
                    newTaskTitle = ""
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
        )
    }
}
