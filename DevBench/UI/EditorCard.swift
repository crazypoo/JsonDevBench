import SwiftUI

struct EditorCard: View {
    let heading: String
    let hint: String
    @Binding var text: String
    var minimumHeight: CGFloat = 310

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(heading).font(.headline)
                Spacer()
                Text("\(text.utf8.count) bytes")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .textBackgroundColor))
                TextEditor(text: $text)
                    .font(.system(size: 13, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .accessibilityLabel(heading)
                if text.isEmpty {
                    Text(hint)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
        }
        .padding(14)
        .frame(minWidth: 270, minHeight: minimumHeight)
    }
}
