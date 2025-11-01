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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("To-Do List")
                .font(.headline)
                .foregroundStyle(.black)

            ForEach(Array(vm.todos.enumerated()), id: \.element.id) { index, todo in
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.toggleTodo(at: index)
                        }
                    }) {
                        Image(systemName: todo.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(todo.completed ? .green : .gray)
                    }
                    .buttonStyle(.plain)

                    Text(todo.title)
                        .foregroundStyle(.black)
                        .strikethrough(todo.completed)
                        .animation(.easeInOut(duration: 0.25), value: todo.completed)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.removeTodo(at: index)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity.combined(with: .move(edge: .top))))
            }

            HStack {
                TextField("New Task", text: $newTodo)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    guard !newTodo.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        vm.addTodo(title: newTodo)
                    }
                    newTodo = ""
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
