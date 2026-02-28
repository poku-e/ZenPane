//
//  TodoListView.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

import SwiftUI

struct TodoListView: View {
    @ObservedObject var vm: DashboardViewModel
    @State private var newTodo: String = ""
    @State private var selectedPriority: TodoPriority = .high
    @State private var includesDueDate = true
    @State private var selectedDate = Date.now
    @State private var activeFilter: TodoFilter = .today
    @FocusState private var isNewTaskFocused: Bool

    private var visibleIndices: [Int] {
        vm.todoIndices(for: activeFilter)
    }

    private var visibleTodoIDs: [Todo.ID] {
        visibleIndices.map { vm.todos[$0].id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            filterBar
            taskList
            quickCapture
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .onAppear {
            if vm.todos.isEmpty {
                isNewTaskFocused = true
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Daily Planning", systemImage: "checkmark.circle")
                    .font(.headline)
                Text("\(vm.todoIndices(for: .today).count) active today • \(vm.overdueCount) overdue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if vm.completedCount > 0 {
                Button("Clear Completed") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        vm.removeCompletedTodos()
                    }
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }
    }

    private var filterBar: some View {
        Picker("Task Filter", selection: $activeFilter) {
            ForEach(TodoFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var taskList: some View {
        Group {
            if visibleIndices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(emptyStateTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(emptyStateMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                .padding(16)
                .background(.thinMaterial.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(visibleTodoIDs, id: \.self) { todoID in
                            todoRow(for: todoID)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var quickCapture: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Capture")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                TextField("Add a task", text: $newTodo)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNewTaskFocused)
                    .onSubmit(addTask)
                    .submitLabel(.done)

                Picker("Priority", selection: $selectedPriority) {
                    ForEach(TodoPriority.allCases) { priority in
                        Text(priority.title).tag(priority)
                    }
                }
                .frame(width: 110)

                Toggle("Due", isOn: $includesDueDate)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help("Attach a due date")

                if includesDueDate {
                    DatePicker(
                        "Due Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                }

                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .keyboardShortcut(.return, modifiers: [.command])
            }

            Text("Shortcut: Command-Return adds the task.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func todoRow(for todoID: Todo.ID) -> some View {
        if let todo = todo(for: todoID) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.toggleTodo(id: todo.id)
                        }
                    }) {
                        Image(systemName: todo.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(todo.completed ? .green : .gray)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(todo.completed ? "Mark incomplete" : "Mark complete")

                    TextField("Task title", text: titleBinding(for: todoID))
                        .textFieldStyle(.plain)
                        .font(.subheadline.weight(.semibold))
                        .strikethrough(todo.completed)

                    Spacer()

                    Button(action: {
                        vm.togglePin(id: todo.id)
                    }) {
                        Image(systemName: todo.isPinned ? "pin.fill" : "pin")
                            .foregroundStyle(todo.isPinned ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(todo.isPinned ? "Unpin task" : "Pin task")

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.removeTodo(id: todo.id)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete task")
                }

                HStack(spacing: 12) {
                    Picker("Priority", selection: priorityBinding(for: todoID)) {
                        ForEach(TodoPriority.allCases) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                    .frame(width: 110)

                    HStack(spacing: 6) {
                        Image(systemName: todo.priority.symbolName)
                            .foregroundStyle(todo.priority.tint)
                        Text(priorityLabel(for: todo.priority))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    DatePicker(
                        "Due Date",
                        selection: dueDateBinding(for: todoID),
                        displayedComponents: .date
                    )
                    .labelsHidden()

                    Button("Clear Date") {
                        vm.updateTodoDueDate(id: todo.id, dueDate: nil)
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Text(todoTimingText(for: todo))
                        .font(.caption)
                        .foregroundStyle(todoTimingColor(for: todo))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.thinMaterial.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity.combined(with: .move(edge: .top))))
        }
    }

    private func todo(for id: Todo.ID) -> Todo? {
        vm.todos.first { $0.id == id }
    }

    private func titleBinding(for id: Todo.ID) -> Binding<String> {
        Binding(
            get: { todo(for: id)?.title ?? "" },
            set: { vm.updateTodoTitle(id: id, title: $0) }
        )
    }

    private func priorityBinding(for id: Todo.ID) -> Binding<TodoPriority> {
        Binding(
            get: { todo(for: id)?.priority ?? .medium },
            set: { vm.updateTodoPriority(id: id, priority: $0) }
        )
    }

    private func dueDateBinding(for id: Todo.ID) -> Binding<Date> {
        Binding(
            get: { todo(for: id)?.dueDate ?? Date.now },
            set: { vm.updateTodoDueDate(id: id, dueDate: $0) }
        )
    }

    private var emptyStateTitle: String {
        switch activeFilter {
        case .today:
            return "No tasks in today’s queue"
        case .upcoming:
            return "Nothing scheduled after today"
        case .completed:
            return "No completed tasks yet"
        }
    }

    private var emptyStateMessage: String {
        switch activeFilter {
        case .today:
            return "Add a few priorities and keep today’s execution list tight."
        case .upcoming:
            return "Use due dates for tasks you want to stage ahead of time."
        case .completed:
            return "Completed work will appear here until you clear it."
        }
    }

    private func priorityLabel(for priority: TodoPriority) -> String {
        switch priority {
        case .high:
            return "High attention"
        case .medium:
            return "Normal attention"
        case .low:
            return "Low attention"
        }
    }

    private func todoTimingText(for todo: Todo) -> String {
        guard let dueDate = todo.dueDate else { return "No due date" }

        if Calendar.current.isDateInToday(dueDate) {
            return "Due today"
        }

        if dueDate < Calendar.current.startOfDay(for: .now) {
            return "Past due"
        }

        return "Due \(dueDate.formatted(date: .abbreviated, time: .omitted))"
    }

    private func todoTimingColor(for todo: Todo) -> Color {
        guard let dueDate = todo.dueDate else { return .secondary }

        if dueDate < Calendar.current.startOfDay(for: .now) {
            return .red
        }

        if Calendar.current.isDateInToday(dueDate) {
            return .orange
        }

        return .secondary
    }

    private func addTask() {
        let trimmed = newTodo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            vm.addTodo(
                title: trimmed,
                priority: selectedPriority,
                dueDate: includesDueDate ? selectedDate : nil,
                pinned: selectedPriority == .high
            )
        }

        newTodo = ""
        selectedPriority = .high
        includesDueDate = true
        selectedDate = .now
        activeFilter = .today
        isNewTaskFocused = true
    }
}
