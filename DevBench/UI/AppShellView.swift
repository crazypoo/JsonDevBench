import SwiftUI

struct AppShellView: View {
    @StateObject private var history = HistoryStore()
    @State private var selection: ToolID? = .jsonFormat
    @State private var search = ""
    @State private var showingHistory = false
    @AppStorage("historyEnabled") private var historyEnabled = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(ToolCategory.allCases) { category in
                        let tools = ToolID.allCases.filter { tool in
                            tool.info.category == category && (search.isEmpty ||
                                tool.info.title.localizedCaseInsensitiveContains(search) ||
                                tool.info.subtitle.localizedCaseInsensitiveContains(search) ||
                                tool.rawValue.localizedCaseInsensitiveContains(search))
                        }
                        if !tools.isEmpty {
                            Section(category.rawValue) {
                                ForEach(tools) { tool in
                                    Label(tool.info.title, systemImage: tool.info.icon)
                                        .tag(tool)
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .searchable(text: $search, prompt: "搜索 32 个开发工具")

                Divider()
                VStack(alignment: .leading, spacing: 11) {
                    Button { showingHistory = true } label: {
                        Label("操作历史", systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Toggle("保存本地历史", isOn: $historyEnabled)
                        .font(.caption)
                        .help("默认关闭。开启后仅在本机保存最多 50 条，每条输入和输出最多 25,000 字符。关闭时清空历史。")
                    HStack {
                        Text("DevBench 0.1.1")
                        Spacer()
                        Image(systemName: "desktopcomputer")
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
                .padding(16)
            }
            .navigationSplitViewColumnWidth(min: 225, ideal: 245, max: 330)
        } detail: {
            if let selection {
                ToolWorkbenchView(tool: selection, history: history)
                    .id(selection)
            } else {
                VStack {
                    Image(systemName: "curlybraces.square").font(.largeTitle)
                    Text("从左侧选择开发工具")
                }
            }
        }
        .navigationTitle("DevBench")
        .onChange(of: historyEnabled) { enabled in if !enabled { history.clear() } }
        .sheet(isPresented: $showingHistory) { HistoryView(history: history) }
    }
}
