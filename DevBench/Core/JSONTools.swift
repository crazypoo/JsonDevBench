import Foundation
import CoreFoundation

enum ToolFailure: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self { case .invalid(let message): return message }
    }
}

enum JSONTools {
    static func parse(_ text: String) throws -> Any {
        guard let data = text.data(using: .utf8) else { throw ToolFailure.invalid("无法读取 UTF-8 文本") }
        do {
            return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            throw ToolFailure.invalid("JSON 校验失败：\(error.localizedDescription)")
        }
    }

    static func stringify(_ value: Any, pretty: Bool = true, sorted: Bool = false) throws -> String {
        var options: JSONSerialization.WritingOptions = [.fragmentsAllowed, .withoutEscapingSlashes]
        if pretty { options.insert(.prettyPrinted) }
        if sorted { options.insert(.sortedKeys) }
        let data = try JSONSerialization.data(withJSONObject: value, options: options)
        return String(decoding: data, as: UTF8.self)
    }

    static func format(_ text: String, pretty: Bool = true, sorted: Bool = false) throws -> String {
        try stringify(parse(text), pretty: pretty, sorted: sorted)
    }

    static func escape(_ text: String) throws -> String {
        try stringify(text, pretty: false)
    }

    static func unescape(_ text: String) throws -> String {
        guard let result = try parse(text) as? String else {
            throw ToolFailure.invalid("请输入包含双引号的 JSON 字符串，例如 \"Hello\\nWorld\"")
        }
        return result
    }

    static func diff(_ oldText: String, _ newText: String) throws -> String {
        let left = try parse(oldText)
        let right = try parse(newText)
        var lines: [String] = []
        func show(_ value: Any) -> String {
            (try? stringify(value, pretty: false, sorted: true)) ?? String(describing: value)
        }
        func walk(_ a: Any, _ b: Any, path: String) {
            if lines.count >= 500 { return }
            if let ad = a as? [String: Any], let bd = b as? [String: Any] {
                for key in Set(ad.keys).union(bd.keys).sorted() {
                    let childPath = path + "." + key
                    switch (ad[key], bd[key]) {
                    case (nil, let value?): lines.append("+ \(childPath): \(show(value))")
                    case (let value?, nil): lines.append("- \(childPath): \(show(value))")
                    case (let left?, let right?): walk(left, right, path: childPath)
                    default: break
                    }
                }
            } else if let aa = a as? [Any], let ba = b as? [Any] {
                for index in 0..<max(aa.count, ba.count) {
                    let childPath = "\(path)[\(index)]"
                    if index >= aa.count { lines.append("+ \(childPath): \(show(ba[index]))") }
                    else if index >= ba.count { lines.append("- \(childPath): \(show(aa[index]))") }
                    else { walk(aa[index], ba[index], path: childPath) }
                }
            } else if show(a) != show(b) {
                lines.append("~ \(path): \(show(a))  →  \(show(b))")
            }
        }
        walk(left, right, path: "$" )
        if lines.isEmpty { return "✓ 两份 JSON 的内容和结构一致（不考虑对象 Key 的顺序）" }
        if lines.count >= 500 { lines.append("… 差异超过 500 项，仅显示前 500 项") }
        return "共发现 \(min(lines.count, 500)) 处差异：\n\n" + lines.joined(separator: "\n")
    }
}

struct JSONNode: Identifiable {
    let id: String
    let key: String
    let summary: String
    let children: [JSONNode]?

    static func tree(for data: Any) -> [JSONNode] {
        [make(data, key: "root", path: "$", depth: 0)]
    }

    private static func make(_ value: Any, key: String, path: String, depth: Int) -> JSONNode {
        // A bound keeps huge/hostile JSON input from generating an unbounded outline.
        if depth >= 40 { return JSONNode(id: path, key: key, summary: "… 已达到树形浏览深度上限", children: nil) }
        if let dictionary = value as? [String: Any] {
            let children = dictionary.keys.sorted().map { name in
                make(dictionary[name]!, key: name, path: path + "." + name, depth: depth + 1)
            }
            return JSONNode(id: path, key: key, summary: "Object · \(dictionary.count) keys", children: children)
        }
        if let array = value as? [Any] {
            return JSONNode(id: path, key: key, summary: "Array · \(array.count) items", children:
                array.enumerated().map { index, item in make(item, key: "[\(index)]", path: "\(path)[\(index)]", depth: depth + 1) })
        }
        if value is NSNull { return JSONNode(id: path, key: key, summary: "null", children: nil) }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return JSONNode(id: path, key: key, summary: number.boolValue ? "true" : "false", children: nil) }
            return JSONNode(id: path, key: key, summary: number.stringValue, children: nil)
        }
        return JSONNode(id: path, key: key, summary: "\"\(String(describing: value))\"", children: nil)
    }
}
