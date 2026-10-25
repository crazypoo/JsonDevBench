import SwiftUI
import AppKit

struct ToolWorkbenchView: View {
    let tool: ToolID
    @ObservedObject var history: HistoryStore

    @State private var input = ""
    @State private var secondary = ""
    @State private var output = ""
    @State private var pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    @State private var replacement = "[email]"
    @State private var outputMode = 0
    @State private var errorMessage: String?
    @State private var statusMessage = "就绪 · 所有计算均在本机完成"
    @State private var running = false
    @State private var runVersion = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: tool.info.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.info.title).font(.title2.weight(.semibold))
                    Text(tool.info.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if running { ProgressView().controlSize(.small) }
                Button {
                    execute()
                } label: {
                    Label("执行", systemImage: "play.fill")
                        .frame(minWidth: 76)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(running)
                .help("执行当前工具 · ⌘ Return")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            if tool.usesRegex {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("正则表达式").font(.caption).foregroundStyle(.secondary)
                        TextField("输入 Regex", text: $pattern)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    if tool == .regexReplace {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("替换模板（支持 $1）").font(.caption).foregroundStyle(.secondary)
                            TextField("替换内容", text: $replacement)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }

            HStack(spacing: 8) {
                Button { FilePanels.open { input = $0; invalidate() } } label: {
                    Label("打开文件", systemImage: "folder")
                }
                Button { input = tool.example; if tool == .jsonDiff { secondary = #"{"user":{"name":"Alice","age":21},"active":false}"# }; invalidate() } label: {
                    Label("载入示例", systemImage: "text.badge.plus")
                }
                Button { input = ""; secondary = ""; output = ""; invalidate() } label: {
                    Label("清空", systemImage: "trash")
                }
                Spacer()
                if tool == .jsonTree && !output.isEmpty {
                    Picker("结果模式", selection: $outputMode) {
                        Text("文本").tag(0)
                        Text("树形").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 120)
                }
                Button { copyOutput() } label: { Label("复制结果", systemImage: "doc.on.doc") }
                    .disabled(output.isEmpty)
                Button { FilePanels.save(output, filename: suggestedFilename) } label: {
                    Label("保存结果", systemImage: "square.and.arrow.down")
                }
                .disabled(output.isEmpty)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider()

            HSplitView {
                VStack(spacing: 0) {
                    EditorCard(heading: tool.usesSecondaryInput ? "JSON A · 原始版本" : "输入", hint: "在此粘贴文本，或打开本地文件…", text: $input, minimumHeight: tool.usesSecondaryInput ? 180 : 310)
                    if tool.usesSecondaryInput {
                        Divider().padding(.horizontal, 14)
                        EditorCard(heading: "JSON B · 对比版本", hint: "在此输入第二份 JSON…", text: $secondary, minimumHeight: 180)
                    }
                }
                .frame(minWidth: 310)

                Group {
                    if tool == .jsonTree && outputMode == 1 && !output.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("树形结果").font(.headline).padding(.horizontal, 16).padding(.top, 15)
                            JSONTreeView(source: output)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 14)
                                .padding(.bottom, 14)
                        }
                    } else {
                        EditorCard(heading: "输出（可编辑）", hint: "执行成功后在此显示结果…", text: $output)
                    }
                }
                .frame(minWidth: 310)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            HStack(spacing: 8) {
                Image(systemName: errorMessage == nil ? "checkmark.circle" : "exclamationmark.triangle")
                    .foregroundStyle(errorMessage == nil ? Color.secondary : Color.orange)
                Text(errorMessage ?? statusMessage)
                    .font(.caption)
                    .lineLimit(2)
                Spacer()
                Text("本地处理 · 不上传数据")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
        }
        .frame(minWidth: 700, minHeight: 460)
        .onChange(of: input) { _ in invalidate(); output = "" }
        .onChange(of: secondary) { _ in invalidate(); output = "" }
        .onChange(of: pattern) { _ in invalidate(); output = "" }
        .onChange(of: replacement) { _ in invalidate(); output = "" }
    }

    private var suggestedFilename: String {
        switch tool {
        case .jsonCSV: return "output.csv"
        case .jsonYAML: return "output.yaml"
        case .jsonSwift: return "Root.swift"
        case .xmlFormat: return "output.xml"
        case .jsonFormat, .jsonMinify, .jsonSort, .jsonTree, .xmlJSON, .csvJSON: return "output.json"
        default: return "output.txt"
        }
    }

    private func invalidate() {
        runVersion += 1
        running = false
        errorMessage = nil
        statusMessage = "输入已更新 · 点击执行或按 ⌘ Return"
    }

    private func execute() {
        runVersion += 1
        let currentVersion = runVersion
        let selected = tool
        let submittedInput = input
        let submittedSecondary = secondary
        let submittedPattern = pattern
        let submittedReplacement = replacement
        running = true
        errorMessage = nil
        statusMessage = "处理中…"
        Task {
            do {
                let processed = try await Task.detached(priority: .userInitiated) {
                    try ToolEngine.execute(selected, input: submittedInput, secondary: submittedSecondary,
                                           pattern: submittedPattern, replacement: submittedReplacement)
                }.value
                guard currentVersion == runVersion else { return }
                output = processed
                running = false
                statusMessage = "处理完成 · 输出 \(processed.utf8.count) bytes"
                history.append(tool: selected, input: submittedInput, output: processed)
            } catch {
                guard currentVersion == runVersion else { return }
                running = false
                output = ""
                errorMessage = error.localizedDescription
            }
        }
    }

    private func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
        statusMessage = "已复制结果到剪贴板"
    }
}
