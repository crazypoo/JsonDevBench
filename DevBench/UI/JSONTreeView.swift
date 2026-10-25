import SwiftUI

struct JSONTreeView: View {
    let source: String
    private var nodes: [JSONNode] {
        guard let parsed = try? JSONTools.parse(source) else { return [] }
        return JSONNode.tree(for: parsed)
    }

    var body: some View {
        List {
            OutlineGroup(nodes, children: \.children) { node in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(node.key)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    Text(node.summary)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.inset)
        .accessibilityLabel("JSON 树形浏览器")
    }
}
