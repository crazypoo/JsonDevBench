import Foundation
#if os(Linux)
// FoundationXML is a separate module in swift-corelibs-foundation on Linux.
// On macOS, XMLParser / XMLDocument are available from Foundation.
import FoundationXML
#endif
import CoreFoundation

private final class XMLJSONDelegate: NSObject, XMLParserDelegate {
    final class Node {
        let name: String
        var attributes: [String: String]
        var content = ""
        var children: [Node] = []
        init(_ name: String, attributes: [String: String]) { self.name = name; self.attributes = attributes }
    }

    var stack: [Node] = []
    var root: Node?
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        stack.append(Node(elementName, attributes: attributeDict))
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        stack.last?.content += string
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        guard let node = stack.popLast() else { return }
        if let parent = stack.last { parent.children.append(node) }
        else { root = node }
    }
    func convert(_ node: Node) -> Any {
        let content = node.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if node.attributes.isEmpty && node.children.isEmpty { return content }
        var result: [String: Any] = [:]
        for (key, value) in node.attributes { result["@" + key] = value }
        for name in Set(node.children.map(\.name)).sorted() {
            let values = node.children.filter { $0.name == name }.map(convert)
            result[name] = values.count == 1 ? values[0] : values
        }
        if !content.isEmpty { result["#text"] = content }
        return result
    }
}

enum XMLTools {
    static func pretty(_ text: String) throws -> String {
        do {
            let document = try XMLDocument(xmlString: text, options: [])
            return String(decoding: document.xmlData(options: [.nodePrettyPrint]), as: UTF8.self)
        } catch { throw ToolFailure.invalid("XML 格式错误：\(error.localizedDescription)") }
    }
    static func toJSON(_ text: String) throws -> String {
        guard let data = text.data(using: .utf8) else { throw ToolFailure.invalid("XML 必须是 UTF-8") }
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        let delegate = XMLJSONDelegate()
        parser.delegate = delegate
        guard parser.parse(), let root = delegate.root else {
            throw ToolFailure.invalid("XML 解析失败：\(parser.parserError?.localizedDescription ?? "未知原因")")
        }
        return try JSONTools.stringify([root.name: delegate.convert(root)], sorted: true)
    }
}

enum YAMLTools {
    static func fromJSON(_ text: String) throws -> String {
        let value = try JSONTools.parse(text)
        func scalar(_ value: Any) -> String? {
            if value is NSNull { return "null" }
            if let number = value as? NSNumber {
                if CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue ? "true" : "false" }
                return number.stringValue
            }
            if let string = value as? String {
                // JSON string literal quoting is valid YAML 1.2 double-quoted syntax.
                return (try? JSONTools.stringify(string, pretty: false)) ?? "\"\""
            }
            return nil
        }
        func render(_ value: Any, indent: Int) -> [String] {
            let pad = String(repeating: " ", count: indent)
            if let object = value as? [String: Any] {
                if object.isEmpty { return [pad + "{}"] }
                return object.keys.sorted().flatMap { key -> [String] in
                    let val = object[key]!
                    let label = (try? JSONTools.stringify(key, pretty: false)) ?? "\"\""
                    if let simple = scalar(val) { return [pad + label + ": " + simple] }
                    let isEmpty = (val as? [Any])?.isEmpty == true || (val as? [String: Any])?.isEmpty == true
                    if isEmpty { return [pad + label + ": " + ((val is [Any]) ? "[]" : "{}") ] }
                    return [pad + label + ":"] + render(val, indent: indent + 2)
                }
            }
            if let array = value as? [Any] {
                if array.isEmpty { return [pad + "[]"] }
                return array.flatMap { item -> [String] in
                    if let simple = scalar(item) { return [pad + "- " + simple] }
                    let lines = render(item, indent: indent + 2)
                    if let first = lines.first {
                        return [pad + "- " + first.dropFirst(indent + 2)] + Array(lines.dropFirst())
                    }
                    return [pad + "- null"]
                }
            }
            return [pad + (scalar(value) ?? "null")]
        }
        return "---\n" + render(value, indent: 0).joined(separator: "\n") + "\n"
    }
}
