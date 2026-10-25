import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var history: HistoryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("本地操作历史").font(.title2.bold())
                Spacer()
                Button("清空历史", role: .destructive) { history.clear() }
                    .disabled(history.entries.isEmpty)
                Button("完成") { dismiss() }
            }
            .padding(20)
            Divider()
            if history.entries.isEmpty {
                ContentUnavailableViewCompat()
            } else {
                List(history.entries) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: item.tool.info.icon)
                            Text(item.tool.info.title).bold()
                            Spacer()
                            Text(item.date, style: .date).foregroundStyle(.secondary)
                            Text(item.date, style: .time).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 10) {
                            Text(item.input.replacingOccurrences(of: "\n", with: " "))
                                .lineLimit(1).font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("复制输入") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(item.input, forType: .string) }
                            Button("复制结果") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(item.output, forType: .string) }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(width: 740, height: 520)
    }
}

private struct ContentUnavailableViewCompat: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath").font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("暂无操作历史").font(.headline)
            Text("默认不保存。可以在侧边栏底部主动开启本地历史记录。")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
