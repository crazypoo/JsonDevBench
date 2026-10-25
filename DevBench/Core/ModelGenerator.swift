import Foundation
import CoreFoundation

enum ModelGenerator {
    private static let reserved: Set<String> = [
        "as", "associatedtype", "break", "case", "catch", "class", "continue", "default", "defer", "do", "else", "enum", "extension", "fallthrough", "false", "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout", "internal", "is", "let", "nil", "operator", "private", "protocol", "public", "repeat", "rethrows", "return", "self", "Self", "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias", "var", "where", "while", "Any", "Type", "Protocol"
    ]

    static func generate(_ text: String) throws -> String {
        let root = try JSONTools.parse(text)
        guard root is [String: Any] || root is [Any] else {
            throw ToolFailure.invalid("JSON → Swift 需要以对象或数组为根节点")
        }
        var generated: [String] = []
        var usedNames = Set<String>()
        var needsDynamicType = false
        func uniqueName(_ raw: String) -> String {
            var candidate = pascal(raw)
            if candidate.isEmpty { candidate = "Item" }
            let original = candidate
            var suffix = 2
            while usedNames.contains(candidate) { candidate = original + String(suffix); suffix += 1 }
            usedNames.insert(candidate)
            return candidate
        }
        func infer(_ value: Any, childName: String) -> String {
            if value is NSNull { needsDynamicType = true; return "JSONValue" }
            if let d = value as? [String: Any] { let name = uniqueName(childName); emit(d, name: name); return name }
            if let values = value as? [Any] {
                guard let first = values.first(where: { !($0 is NSNull) }) else {
                    needsDynamicType = true
                    return "[JSONValue]"
                }
                let signatures = values.map { semanticSignature($0) }
                if signatures.contains("null") || Set(signatures).count > 1 {
                    needsDynamicType = true
                    return "[JSONValue]"
                }
                if signatures.first == "number", values.contains(where: { value in
                    guard let n = value as? NSNumber else { return false }
                    return ["f", "d"].contains(String(cString: n.objCType))
                }) { return "[Double]" }
                return "[\(infer(first, childName: childName + "Item"))]"
            }
            if let n = value as? NSNumber {
                if CFGetTypeID(n) == CFBooleanGetTypeID() { return "Bool" }
                return ["f", "d"].contains(String(cString: n.objCType)) ? "Double" : "Int"
            }
            return "String"
        }
        func render(_ dictionary: [String: Any], name: String) -> String {
            var lines = ["struct \(name): Codable {"]
            var coding: [(String, String)] = []
            var seen = Set<String>()
            for key in dictionary.keys.sorted() {
                var property = camel(key)
                if property.isEmpty { property = "value" }
                if property.first?.isNumber == true { property = "_" + property }
                if reserved.contains(property) { property = "`\(property)`" }
                let stem = property
                var index = 2
                while seen.contains(property) { property = stem + String(index); index += 1 }
                seen.insert(property)
                let type = infer(dictionary[key]!, childName: name + pascal(key))
                let nullable = dictionary[key] is NSNull
                lines.append("    let \(property): \(type)\(nullable ? "?" : "")")
                if property.replacingOccurrences(of: "`", with: "") != key { coding.append((property, key)) }
            }
            if !coding.isEmpty {
                lines.append("\n    enum CodingKeys: String, CodingKey {")
                for key in dictionary.keys.sorted() {
                    let property = propertyName(key, from: dictionary.keys.sorted())
                    if let renamed = coding.first(where: { $0.1 == key }) {
                        lines.append("        case \(renamed.0) = \"\(escapeSwiftLiteral(key))\"")
                    } else { lines.append("        case \(property)") }
                }
                lines.append("    }")
            }
            lines.append("}")
            return lines.joined(separator: "\n")
        }
        func emit(_ dictionary: [String: Any], name: String) {
            generated.append(render(dictionary, name: name))
        }

        if let dict = root as? [String: Any] {
            usedNames.insert("Root")
            emit(dict, name: "Root")
        } else if let array = root as? [Any] {
            let first = array.first(where: { $0 is [String: Any] }) as? [String: Any]
            guard let first else { throw ToolFailure.invalid("根数组需要至少包含一个 JSON 对象用于推断字段") }
            usedNames.insert("RootItem")
            emit(first, name: "RootItem")
        }
        let prefix = "// DevBench · 根据样本推断 Codable 结构\n// 注意：缺失字段、混合类型或 null 请根据真实 API 手动调整。\nimport Foundation\n\n"
        let alias = root is [Any] ? "\ntypealias Root = [RootItem]\n" : ""
        return prefix + generated.joined(separator: "\n\n") + alias + (needsDynamicType ? "\n\n" + dynamicValueImplementation : "")
    }

    private static func propertyName(_ key: String, from keys: [String]) -> String {
        var result = camel(key)
        if result.isEmpty { result = "value" }
        if result.first?.isNumber == true { result = "_" + result }
        if reserved.contains(result) { result = "`\(result)`" }
        // The typical case stays stable. Collisions are handled by coding above.
        return result
    }

    private static func camel(_ text: String) -> String {
        let segments = text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        guard let first = segments.first else { return "" }
        return first.prefix(1).lowercased() + first.dropFirst() + segments.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }
    private static func pascal(_ text: String) -> String {
        let c = camel(text)
        return c.prefix(1).uppercased() + c.dropFirst()
    }
    private static func escapeSwiftLiteral(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
    private static func semanticSignature(_ value: Any) -> String {
        if value is NSNull { return "null" }
        if value is [String: Any] { return "object" }
        if value is [Any] { return "array" }
        if let n = value as? NSNumber { return CFGetTypeID(n) == CFBooleanGetTypeID() ? "bool" : "number" }
        return "string"
    }
    private static let dynamicValueImplementation = """
    // Heterogeneous arrays are represented by JSONValue.
    indirect enum JSONValue: Codable {
        case string(String), number(Double), bool(Bool)
        case object([String: JSONValue]), array([JSONValue]), null

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if c.decodeNil() { self = .null }
            else if let v = try? c.decode(Bool.self) { self = .bool(v) }
            else if let v = try? c.decode(Double.self) { self = .number(v) }
            else if let v = try? c.decode(String.self) { self = .string(v) }
            else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
            else { self = .array(try c.decode([JSONValue].self)) }
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case .string(let v): try c.encode(v)
            case .number(let v): try c.encode(v)
            case .bool(let v): try c.encode(v)
            case .object(let v): try c.encode(v)
            case .array(let v): try c.encode(v)
            case .null: try c.encodeNil()
            }
        }
    }
    """
}
