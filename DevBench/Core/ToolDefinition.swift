import Foundation

enum ToolCategory: String, CaseIterable, Identifiable {
    case json = "JSON"
    case data = "数据转换"
    case encoding = "编码与解码"
    case security = "哈希与安全"
    case text = "文本处理"
    case time = "日期与时间"

    var id: String { rawValue }
}

enum ToolID: String, CaseIterable, Hashable, Identifiable, Codable, Sendable {
    case jsonFormat, jsonMinify, jsonSort, jsonEscape, jsonUnescape, jsonTree
    case jsonSwift, jsonCSV, csvJSON, jsonYAML, xmlFormat, xmlJSON, jsonDiff
    case base64Encode, base64Decode, urlEncode, urlDecode, htmlEscape, htmlUnescape
    case unicodeEscape, unicodeUnescape
    case md5, sha256, sha512, jwtDecode, uuid
    case regexFind, regexReplace, upper, lower, trim
    case timestamp

    var id: String { rawValue }

    var info: ToolInfo {
        switch self {
        case .jsonFormat: return .init("JSON 格式化", "校验、缩进和高亮友好输出", "curlybraces", .json)
        case .jsonMinify: return .init("JSON 压缩", "移除多余空白", "arrow.down.right.and.arrow.up.left", .json)
        case .jsonSort: return .init("JSON Key 排序", "按字母顺序排列 JSON Key", "arrow.up.arrow.down", .json)
        case .jsonEscape: return .init("JSON 字符串转义", "转换为合法 JSON 字符串", "quote.bubble", .json)
        case .jsonUnescape: return .init("JSON 字符串反转义", "解析 JSON 字符串字面量", "text.quote", .json)
        case .jsonTree: return .init("JSON 树形浏览", "折叠浏览对象和数组", "list.bullet.indent", .json)
        case .jsonSwift: return .init("JSON → Swift", "生成 Codable 模型", "swift", .data)
        case .jsonCSV: return .init("JSON → CSV", "对象数组导出 CSV", "tablecells", .data)
        case .csvJSON: return .init("CSV → JSON", "处理引号、逗号和换行", "tablecells.fill", .data)
        case .jsonYAML: return .init("JSON → YAML", "生成 YAML 格式文本", "doc.text", .data)
        case .xmlFormat: return .init("XML 格式化", "校验并整理 XML", "chevron.left.forwardslash.chevron.right", .data)
        case .xmlJSON: return .init("XML → JSON", "元素和属性转换为 JSON", "arrow.left.arrow.right", .data)
        case .jsonDiff: return .init("JSON 差异对比", "比较两份 JSON 结构", "rectangle.split.2x1", .data)
        case .base64Encode: return .init("Base64 编码", "UTF-8 转 Base64", "lock.doc", .encoding)
        case .base64Decode: return .init("Base64 解码", "Base64 转 UTF-8", "lock.open", .encoding)
        case .urlEncode: return .init("URL 编码", "百分号编码文本", "link", .encoding)
        case .urlDecode: return .init("URL 解码", "百分号解码文本", "link.badge.plus", .encoding)
        case .htmlEscape: return .init("HTML 转义", "替换特殊 HTML 字符", "chevron.left.forwardslash.chevron.right", .encoding)
        case .htmlUnescape: return .init("HTML 反转义", "还原常见 HTML 实体", "chevron.left.forwardslash.chevron.right", .encoding)
        case .unicodeEscape: return .init("Unicode 转义", "UTF-16 \\uXXXX 序列", "character.book.closed", .encoding)
        case .unicodeUnescape: return .init("Unicode 反转义", "解析 \\uXXXX 序列", "character.cursor.ibeam", .encoding)
        case .md5: return .init("MD5 摘要", "生成 MD5 校验值（非安全用途）", "number", .security)
        case .sha256: return .init("SHA-256", "生成 SHA-256 摘要", "number.square", .security)
        case .sha512: return .init("SHA-512", "生成 SHA-512 摘要", "number.square.fill", .security)
        case .jwtDecode: return .init("JWT 解码", "只解析 Header / Payload，不验证签名", "key.horizontal", .security)
        case .uuid: return .init("UUID 生成", "生成随机 UUID v4", "number", .security)
        case .regexFind: return .init("正则匹配", "查看所有匹配项及范围", "text.magnifyingglass", .text)
        case .regexReplace: return .init("正则替换", "正则批量替换内容", "text.badge.plus", .text)
        case .upper: return .init("转换大写", "文本转大写", "textformat.abc.dottedunderline", .text)
        case .lower: return .init("转换小写", "文本转小写", "textformat.abc", .text)
        case .trim: return .init("清理空白", "清除首尾空白及空行", "text.alignleft", .text)
        case .timestamp: return .init("时间戳转换", "秒 / 毫秒与日期互转", "clock.arrow.circlepath", .time)
        }
    }

    var example: String {
        switch self {
        case .jsonFormat, .jsonMinify, .jsonSort, .jsonTree, .jsonSwift, .jsonYAML:
            return #"{"name":"DevBench","version":1,"user":{"id":42,"active":true},"tags":["macOS","Swift"]}"#
        case .jsonEscape: return "Hello \"Swift\"\nmacOS"
        case .jsonUnescape: return #""Hello \"Swift\"\nmacOS""#
        case .jsonCSV: return #"[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]"#
        case .csvJSON: return "id,name,city\n1,Alice,Beijing\n2,Bob,Shanghai"
        case .xmlFormat, .xmlJSON: return "<root><user id=\"42\"><name>Alice</name></user></root>"
        case .jsonDiff: return #"{"user":{"name":"Alice","age":20},"active":true}"#
        case .base64Encode: return "Hello, DevBench!"
        case .base64Decode: return "SGVsbG8sIERldkJlbmNoIQ=="
        case .urlEncode: return "Swift JSON & macOS / 中文"
        case .urlDecode: return "Swift%20JSON%20%26%20macOS"
        case .htmlEscape: return "<div title=\"a&b\">Hello</div>"
        case .htmlUnescape: return "&lt;div&gt;Hello &amp; Swift&lt;/div&gt;"
        case .unicodeEscape: return "你好，Swift 👋"
        case .unicodeUnescape: return #"\u4F60\u597D\uFF0CSwift"#
        case .md5, .sha256, .sha512: return "DevBench"
        case .jwtDecode: return "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFsaWNlIn0."
        case .uuid: return ""
        case .regexFind, .regexReplace: return "Contact alice@example.com or bob@example.org"
        case .upper, .lower, .trim: return "  Swift DevBench  \n  JSON tools  "
        case .timestamp: return "1761379200"
        }
    }

    var supportsEmptyInput: Bool { self == .uuid }
    var usesSecondaryInput: Bool { self == .jsonDiff }
    var usesRegex: Bool { self == .regexFind || self == .regexReplace }
}

struct ToolInfo {
    let title: String
    let subtitle: String
    let icon: String
    let category: ToolCategory

    init(_ title: String, _ subtitle: String, _ icon: String, _ category: ToolCategory) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
    }
}
