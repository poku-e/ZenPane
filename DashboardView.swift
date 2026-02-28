//
//  DashboardView.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//


//
//  DashboardView.swift
//  Zenpane
//
//  Created by Corey Richardson on 11/1/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow,
                             blendingMode: .withinWindow)
                .ignoresSafeArea()
                .cornerRadius(24)

            VStack(spacing: 24) {
                // Quote Section
                VStack(spacing: 8) {
                    Text(vm.quote)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black)
                        .frame(maxWidth: 480)
                        .id(vm.quote)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.4), value: vm.quote)

                    if !vm.author.isEmpty {
                        Text("— \(vm.author)")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }

                Divider().background(.black.opacity(0.3))

                // Weather
                HStack(spacing: 12) {
                    Image(systemName: "cloud.sun.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.orange, .yellow)
                    Text(vm.weather)
                        .font(.headline)
                        .foregroundStyle(.black.opacity(0.85))
                        .id(vm.weather)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.4), value: vm.weather)
                }

                Divider().background(.black.opacity(0.3))

                // To-Do List
                TodoListView(vm: vm)
            }
            .padding(32)
        }
        .frame(width: 600, height: 450)
        .onAppear { vm.loadData() }
    }
}
