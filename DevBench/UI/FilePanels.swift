import AppKit
import Foundation
import UniformTypeIdentifiers

enum FilePanels {
    static func open(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .json, .xml, .commaSeparatedText, .data]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.message = "选择 UTF-8 文本、JSON、CSV 或 XML 文件"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let bytes = attributes[.size] as? NSNumber, bytes.int64Value > 10_000_000 {
                    throw ToolFailure.invalid("文件超过 10 MB。首版编辑器限制为 10 MB 以内的文本文件。")
                }
                var text = try String(contentsOf: url, encoding: .utf8)
                if text.first == "\u{FEFF}" { text.removeFirst() }
                completion(text)
            } catch { showError(error) }
        }
    }

    static func save(_ text: String, filename: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = filename
        panel.canCreateDirectories = true
        panel.message = "保存本地处理结果"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do { try text.write(to: url, atomically: true, encoding: .utf8) }
            catch { showError(error) }
        }
    }

    private static func showError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "文件操作失败"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
