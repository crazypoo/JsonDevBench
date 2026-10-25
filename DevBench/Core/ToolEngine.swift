import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

// Pure local transformations. No network calls, analytics SDK, or external server.
enum ToolEngine {
    static func execute(_ tool: ToolID, input: String, secondary: String = "",
                        pattern: String = "", replacement: String = "") throws -> String {
        if input.isEmpty && !tool.supportsEmptyInput { throw ToolFailure.invalid("请先输入内容或点击“载入示例”") }
        switch tool {
        case .jsonFormat, .jsonTree: return try JSONTools.format(input)
        case .jsonMinify: return try JSONTools.format(input, pretty: false)
        case .jsonSort: return try JSONTools.format(input, sorted: true)
        case .jsonEscape: return try JSONTools.escape(input)
        case .jsonUnescape: return try JSONTools.unescape(input)
        case .jsonSwift: return try ModelGenerator.generate(input)
        case .jsonCSV: return try CSVTools.jsonToCSV(input)
        case .csvJSON: return try CSVTools.csvToJSON(input)
        case .jsonYAML: return try YAMLTools.fromJSON(input)
        case .xmlFormat: return try XMLTools.pretty(input)
        case .xmlJSON: return try XMLTools.toJSON(input)
        case .jsonDiff: return try JSONTools.diff(input, secondary)
        case .base64Encode: return Data(input.utf8).base64EncodedString()
        case .base64Decode:
            let normalized = input.components(separatedBy: .whitespacesAndNewlines).joined()
            guard let data = Data(base64Encoded: normalized),
                  let string = String(data: data, encoding: .utf8) else { throw ToolFailure.invalid("Base64 无效，或解码数据并非 UTF-8 文本") }
            return string
        case .urlEncode:
            let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
            return input.addingPercentEncoding(withAllowedCharacters: allowed) ?? input
        case .urlDecode:
            guard let result = input.removingPercentEncoding else { throw ToolFailure.invalid("URL 中有不合法的百分号编码") }
            return result
        case .htmlEscape:
            return input.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        case .htmlUnescape: return decodeHTML(input)
        case .unicodeEscape:
            return input.utf16.map { unit -> String in
                if unit < 0x20 || unit > 0x7E { return String(format: "\\u%04X", unit) }
                return String(UnicodeScalar(unit)!)
            }.joined()
        case .unicodeUnescape:
            let wrapped = "\"" + input.replacingOccurrences(of: "\"", with: "\\\"") + "\""
            guard let result = try? JSONTools.parse(wrapped) as? String else {
                throw ToolFailure.invalid("Unicode 转义文本错误：请检查 \\uXXXX 序列和代理项")
            }
            return result
        case .md5:
#if canImport(CryptoKit)
            return digest(Insecure.MD5.hash(data: Data(input.utf8)))
#else
            throw ToolFailure.invalid("当前平台不支持 CryptoKit")
#endif
        case .sha256:
#if canImport(CryptoKit)
            return digest(SHA256.hash(data: Data(input.utf8)))
#else
            throw ToolFailure.invalid("当前平台不支持 CryptoKit")
#endif
        case .sha512:
#if canImport(CryptoKit)
            return digest(SHA512.hash(data: Data(input.utf8)))
#else
            throw ToolFailure.invalid("当前平台不支持 CryptoKit")
#endif
        case .jwtDecode: return try decodeJWT(input)
        case .uuid: return UUID().uuidString
        case .regexFind: return try regexMatches(input, pattern: pattern)
        case .regexReplace:
            guard !pattern.isEmpty else { throw ToolFailure.invalid("请输入正则表达式") }
            let expression = try NSRegularExpression(pattern: pattern)
            return expression.stringByReplacingMatches(in: input, range: NSRange(input.startIndex..., in: input), withTemplate: replacement)
        case .upper: return input.uppercased()
        case .lower: return input.lowercased()
        case .trim:
            return input.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }.joined(separator: "\n")
        case .timestamp: return try convertTimestamp(input)
        }
    }

    private static func digest<H: Sequence>(_ hash: H) -> String where H.Element == UInt8 {
        hash.map { String(format: "%02x", $0) }.joined()
    }

    private static func decodeJWT(_ input: String) throws -> String {
        let parts = input.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { throw ToolFailure.invalid("JWT 必须有 Header.Payload.Signature 三段") }
        func decodePart(_ part: Substring) throws -> String {
            var text = String(part).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            text += String(repeating: "=", count: (4 - text.count % 4) % 4)
            guard let data = Data(base64Encoded: text), let json = String(data: data, encoding: .utf8) else {
                throw ToolFailure.invalid("JWT Header 或 Payload 并非有效的 Base64URL")
            }
            return try JSONTools.format(json)
        }
        let header = try decodePart(parts[0])
        let payload = try decodePart(parts[1])
        return "HEADER\n\(header)\n\nPAYLOAD\n\(payload)\n\n⚠️ 仅解码显示，未验证签名、有效期或可信度。"
    }

    private static func decodeHTML(_ text: String) -> String {
        let rx = try! NSRegularExpression(pattern: "&#(?:[xX]([0-9A-Fa-f]+)|([0-9]+));")
        let output = NSMutableString(string: text)
        let matches = rx.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            let hexRange = match.range(at: 1)
            let decRange = match.range(at: 2)
            let hex = hexRange.location != NSNotFound
            let range = hex ? hexRange : decRange
            let value = (text as NSString).substring(with: range)
            if let num = UInt32(value, radix: hex ? 16 : 10), let scalar = UnicodeScalar(num) {
                output.replaceCharacters(in: match.range, with: String(scalar))
            }
        }
        return (output as String)
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: "\u{00A0}")
            .replacingOccurrences(of: "&amp;", with: "&")
    }

    private static func regexMatches(_ input: String, pattern: String) throws -> String {
        guard !pattern.isEmpty else { throw ToolFailure.invalid("请输入正则表达式") }
        let expression = try NSRegularExpression(pattern: pattern)
        let matches = expression.matches(in: input, range: NSRange(input.startIndex..., in: input))
        if matches.isEmpty { return "没有匹配项" }
        let entries = matches.prefix(500).enumerated().map { index, match -> String in
            let value = (input as NSString).substring(with: match.range)
            let groups = (1..<match.numberOfRanges).compactMap { group -> String? in
                let range = match.range(at: group)
                guard range.location != NSNotFound else { return nil }
                return "  分组 \(group): " + (input as NSString).substring(with: range)
            }
            return "#\(index + 1) [UTF-16: \(match.range.location), 长度: \(match.range.length)]  \(value)" + (groups.isEmpty ? "" : "\n" + groups.joined(separator: "\n"))
        }
        return "匹配 \(matches.count) 项\n\n" + entries.joined(separator: "\n\n") + (matches.count > 500 ? "\n\n… 仅显示前 500 项" : "")
    }

    private static func convertTimestamp(_ input: String) throws -> String {
        let input = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let date: Date
        if let number = Double(input), number.isFinite {
            date = Date(timeIntervalSince1970: abs(number) >= 100_000_000_000 ? number / 1000 : number)
        } else {
            let parser = DateFormatter()
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.timeZone = .current
            parser.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let iso = ISO8601DateFormatter()
            let isoWithFraction = ISO8601DateFormatter()
            isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let parsed = isoWithFraction.date(from: input) ?? iso.date(from: input) ?? parser.date(from: input) else {
                throw ToolFailure.invalid("请输入 Unix 时间戳，或 yyyy-MM-dd HH:mm:ss / ISO 8601 日期")
            }
            date = parsed
        }
        let local = DateFormatter()
        local.locale = Locale(identifier: "en_US_POSIX")
        local.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        local.timeZone = .current
        let utc = DateFormatter()
        utc.locale = Locale(identifier: "en_US_POSIX")
        utc.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return "Unix 秒: \(Int64(date.timeIntervalSince1970))\nUnix 毫秒: \(Int64(date.timeIntervalSince1970 * 1000))\n本地时间: \(local.string(from: date))\nUTC: \(utc.string(from: date))\nISO 8601: \(iso.string(from: date))"
    }
}
