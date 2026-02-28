import SwiftUI

struct NotesView: View {
    @AppStorage("pinnedNotesText") private var pinnedNotesText: String = ""
    @AppStorage("notesText") private var notesText: String = ""
    @State private var lastSavedAt = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Notes", systemImage: "note.text")
                        .font(.headline)
                    Text("Pinned details and a live scratchpad.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Saved \(lastSavedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            noteSection(
                title: "Pinned",
                subtitle: "Stable references you want visible all day.",
                text: $pinnedNotesText,
                minHeight: 120
            )

            noteSection(
                title: "Scratchpad",
                subtitle: "Capture quick thoughts, reminders, and loose planning.",
                text: $notesText,
                minHeight: 220
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Notes panel")
        .onChange(of: pinnedNotesText) { _, _ in
            lastSavedAt = .now
        }
        .onChange(of: notesText) { _, _ in
            lastSavedAt = .now
        }
    }

    private func noteSection(
        title: String,
        subtitle: String,
        text: Binding<String>,
        minHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: .infinity)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.separator.opacity(0.4))
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(12)
        .background(.thinMaterial.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NotesView()
}
