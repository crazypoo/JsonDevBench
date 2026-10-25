import Foundation

enum CSVTools {
    static func read(_ input: String) throws -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var justClosedQuote = false
        let chars = Array(input.unicodeScalars)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if quoted {
                if ch == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" { field.append("\""); i += 1 }
                    else { quoted = false; justClosedQuote = true }
                } else { field.append(String(ch)) }
            } else {
                switch ch {
                case "\"" where field.isEmpty && !justClosedQuote:
                    quoted = true
                case ",":
                    row.append(field); field = ""; justClosedQuote = false
                case "\n", "\r":
                    row.append(field); field = ""; justClosedQuote = false
                    if !(row.count == 1 && row[0].isEmpty) { rows.append(row) }
                    row = []
                    if ch == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" { i += 1 }
                case "\"":
                    throw ToolFailure.invalid("CSV 格式错误：字段内部出现未转义双引号")
                default:
                    if justClosedQuote && ch != " " && ch != "\t" {
                        throw ToolFailure.invalid("CSV 格式错误：右引号后只允许分隔符")
                    }
                    if !justClosedQuote { field.append(String(ch)) }
                }
            }
            i += 1
        }
        if quoted { throw ToolFailure.invalid("CSV 格式错误：引号没有闭合") }
        if !row.isEmpty || !field.isEmpty || justClosedQuote { row.append(field); rows.append(row) }
        return rows
    }

    static func csvToJSON(_ input: String) throws -> String {
        let rows = try read(input)
        guard let header = rows.first, !header.isEmpty else { throw ToolFailure.invalid("CSV 需要首行列名") }
        let headers = header.enumerated().map { index, name in
            index == 0 ? name.replacingOccurrences(of: "\u{FEFF}", with: "") : name
        }
        guard Set(headers).count == headers.count else { throw ToolFailure.invalid("CSV 存在重复列名，请先更正") }
        let result = try rows.dropFirst().enumerated().map { index, row -> [String: String] in
            guard row.count == headers.count else {
                throw ToolFailure.invalid("CSV 第 \(index + 2) 行有 \(row.count) 列，预期 \(headers.count) 列")
            }
            return Dictionary(uniqueKeysWithValues: zip(headers, row))
        }
        return try JSONTools.stringify(result, sorted: true)
    }

    static func jsonToCSV(_ input: String) throws -> String {
        guard let objects = try JSONTools.parse(input) as? [[String: Any]] else {
            throw ToolFailure.invalid("JSON → CSV 需要对象数组，例如 [{\"id\":1}]")
        }
        guard !objects.isEmpty else { return "" }
        let headers = Array(Set(objects.flatMap(\.keys))).sorted()
        func cell(_ value: Any?) -> String {
            guard let value, !(value is NSNull) else { return "" }
            if let string = value as? String { return string }
            if let value = try? JSONTools.stringify(value, pretty: false, sorted: true) { return value }
            return String(describing: value)
        }
        func encode(_ value: String) -> String {
            if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
                return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            }
            return value
        }
        return ([headers.map(encode).joined(separator: ",")] + objects.map { object in
            headers.map { encode(cell(object[$0])) }.joined(separator: ",")
        }).joined(separator: "\r\n")
    }
}
