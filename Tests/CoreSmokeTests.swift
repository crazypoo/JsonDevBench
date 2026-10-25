import Foundation

@main
struct CoreSmokeTests {
    static func main() throws {
        func check(_ condition: Bool, _ reason: String) {
            if !condition { fatalError("TEST FAILED: " + reason) }
        }
        let fmt = try ToolEngine.execute(.jsonFormat, input: #"{"b":2,"a":1}"#)
        check(fmt.contains("\n"), "JSON format")
        let sorted = try ToolEngine.execute(.jsonSort, input: #"{"z":1,"a":2}"#)
        check(sorted.range(of: "\"a\"")!.lowerBound < sorted.range(of: "\"z\"")!.lowerBound, "JSON sort")
        let compressed = try ToolEngine.execute(.jsonMinify, input: fmt)
        check(!compressed.contains("\n"), "JSON minify")
        let escaped = try ToolEngine.execute(.jsonEscape, input: "Hi\nSwift")
        check(try ToolEngine.execute(.jsonUnescape, input: escaped) == "Hi\nSwift", "JSON string escape")
        let csv = try ToolEngine.execute(.jsonCSV, input: #"[{"name":"A, B","id":1},{"id":2,"name":"C"}]"#)
        let reverse = try ToolEngine.execute(.csvJSON, input: csv)
        check(reverse.contains("A, B"), "CSV quote roundtrip")
        let multiline = try CSVTools.read("id,desc\n1,\"line1\nline2\"\n")
        check(multiline.count == 2 && multiline[1][1] == "line1\nline2", "CSV multiline")
        let xml = try ToolEngine.execute(.xmlJSON, input: "<root><item id=\"1\">hello</item><item>bye</item></root>")
        check(xml.contains("@id"), "XML attributes")
        check(xml.contains("hello"), "XML text")
        let yaml = try ToolEngine.execute(.jsonYAML, input: #"{"name":"Alice","nested":[1,2]}"#)
        check(yaml.contains("\"name\""), "YAML serialization")
        let diff = try ToolEngine.execute(.jsonDiff, input: #"{"a":1}"#, secondary: #"{"a":2}"#)
        check(diff.contains("~ $.a"), "JSON difference")
        let model = try ModelGenerator.generate(#"{"created_at":"today","user":{"id":1},"is_ok":true}"#)
        check(model.contains("struct Root: Codable"), "Swift struct")
        check(model.contains("CodingKeys"), "Swift coding keys")
        let url = try ToolEngine.execute(.urlEncode, input: "a b&中文")
        check(try ToolEngine.execute(.urlDecode, input: url) == "a b&中文", "URL roundtrip")
        let base64 = try ToolEngine.execute(.base64Encode, input: "Hello 中文")
        check(try ToolEngine.execute(.base64Decode, input: base64) == "Hello 中文", "Base64 roundtrip")
        let unicode = try ToolEngine.execute(.unicodeEscape, input: "你好👋")
        check(try ToolEngine.execute(.unicodeUnescape, input: unicode) == "你好👋", "Unicode roundtrip")
        let html = try ToolEngine.execute(.htmlEscape, input: "<b>&</b>")
        check(try ToolEngine.execute(.htmlUnescape, input: html) == "<b>&</b>", "HTML roundtrip")
        let regex = try ToolEngine.execute(.regexFind, input: "one two", pattern: #"\w+"#)
        check(regex.contains("匹配 2 项"), "Regex match")
        let changed = try ToolEngine.execute(.regexReplace, input: "abc123", pattern: #"\d+"#, replacement: "-")
        check(changed == "abc-", "Regex replacement")
        let jwt = try ToolEngine.execute(.jwtDecode, input: ToolID.jwtDecode.example)
        check(jwt.contains("Alice"), "JWT decode")
        let dates = try ToolEngine.execute(.timestamp, input: "1761379200")
        check(dates.contains("Unix 毫秒"), "Timestamp")
        check(UUID(uuidString: try ToolEngine.execute(.uuid, input: "")) != nil, "UUID")
        print("PASS: DevBench core smoke tests")
    }
}
