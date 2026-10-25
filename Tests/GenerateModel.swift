import Foundation
@main
struct TestModel {
    static func main() throws {
        let samples = [
            #"{"created_at":"now","user":{"id":1,"enabled":true},"tags":["hi","there"]}"#,
            #"{"foo-bar":1,"fooBar":2,"value":null,"self":false,"list":[1,"x",null]}"#,
            #"[{"a":1,"b":[{"x":true}]}]"#,
            #"{"x":{},"array":[],"other":[null,null]}"#
        ]
        for (index, sample) in samples.enumerated() {
            let text = try ModelGenerator.generate(sample)
            let outputDirectory = ProcessInfo.processInfo.environment["DEVBENCH_MODEL_OUTPUT_DIR"] ?? NSTemporaryDirectory()
            let path = (outputDirectory as NSString).appendingPathComponent("devbench_model_\(index).swift")
            try text.write(toFile: path, atomically: true, encoding: .utf8)
            print(path)
        }
    }
}
