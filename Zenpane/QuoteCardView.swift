import SwiftUI

struct QuoteCardView: View {
    let quote: String
    let author: String
    let theme: String
    let savedQuoteCount: Int
    let isSaved: Bool
    let onRefresh: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Motivation", systemImage: "sparkles")
                        .font(.headline)
                    Text("Theme: \(theme)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onSave) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.borderless)
                .help(isSaved ? "Quote already saved" : "Save quote")
                .disabled(isSaved)
                .keyboardShortcut("d", modifiers: [.command])

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh quote")
                .keyboardShortcut("r", modifiers: [.command])
            }

            Text(quote)
                .font(.title3)
                .fontWeight(.medium)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)

            if !author.isEmpty {
                Text(author)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("\(savedQuoteCount) saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if isSaved {
                    Text("Saved")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Motivational quote panel")
    }
}

#Preview {
    QuoteCardView(
        quote: "Stay hungry, stay foolish.",
        author: "Steve Jobs",
        theme: "Focus",
        savedQuoteCount: 4,
        isSaved: false,
        onRefresh: {},
        onSave: {}
    )
}
