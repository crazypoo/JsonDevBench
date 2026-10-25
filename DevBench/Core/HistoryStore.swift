import Foundation
import Combine

struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let tool: ToolID
    let input: String
    let output: String
}

final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    private let storageKey = "DevBench.History.v1"

    init() {
        guard UserDefaults.standard.bool(forKey: "historyEnabled"),
              let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = list
    }

    func append(tool: ToolID, input: String, output: String) {
        guard UserDefaults.standard.bool(forKey: "historyEnabled") else { return }
        // Keep a short local history. Enable this only if your input is not sensitive.
        entries.insert(HistoryEntry(id: UUID(), date: .now, tool: tool,
                                    input: String(input.prefix(25_000)),
                                    output: String(output.prefix(25_000))), at: 0)
        entries = Array(entries.prefix(50))
        save()
    }

    func clear() {
        entries.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
