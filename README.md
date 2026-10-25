# DevBench for macOS · v0.1.1

一个使用 **Swift + SwiftUI** 编写的原生 macOS 开发者工具箱，参考 BeJSON（https://www.bejson.com/）的功能分类，但 UI 和代码均为独立实现；**与 BeJSON 网站及其运营方无关联**。

## 0.1.1 编译问题修复说明（2026-10-25）

这一版修复了原 0.1.0 中的两个**确定存在**的跨平台/SwiftUI 编译问题：

1. `XMLTools.swift` 不再无条件 `import FoundationXML`。现在只在 `#if os(Linux)` 下导入该模块；macOS 通过 `Foundation` 使用 `XMLParser` 和 `XMLDocument`。
2. `JSONTreeView.swift` 原本写作 `.system(size: 13, design: .monospaced, weight: .semibold)`，与 SwiftUI 的 API 参数顺序不符。已改为 `.system(size: 13, weight: .semibold, design: .monospaced)`。

另外新增了共享的 `DevBench.xcscheme`，避免脚本和 CI 依赖 Xcode 自动生成用户私有 Scheme；提供 `scripts/verify.sh` 统一进行核心测试、Swift 语法检查、模型代码类型检查、项目文件检查。`/.github/workflows/macos-build.yml` 则在 macOS GitHub Actions runner 上执行 Debug + Release 的实际 Xcode 构建。

**验证范围：** 本交付环境运行 Linux，已执行 `bash scripts/verify.sh` 并通过所有 Linux 可运行检查。**无法在此环境执行 Xcode 的 AppKit/SwiftUI 类型检查和完整 macOS 编译，因此不声称已经实际构建通过。** 请在 Mac 上执行同一脚本以完成最终验收。

## 快速运行（必读）

环境：**macOS 13 Ventura 或更高版本，Xcode 15 或更高版本**。

1. 解压 `DevBench-macOS-0.1.1.zip`。
2. 使用 Xcode 打开 `DevBench.xcodeproj`（**不是**单独打开某个 `.swift`）。
3. 顶部 Scheme 选择 `DevBench`，运行设备选择 `My Mac`。
4. 按 **⌘R** 运行。App 会在 Xcode 中以 macOS 窗口启动。

或者在 Mac 终端运行：

```bash
cd DevBench-macOS
bash scripts/verify.sh        # 在 macOS 上：核心测试 + Debug/Release 两种配置编译
bash scripts/build_mac.sh     # 生成 dist/DevBench.app
open dist/DevBench.app
```

这会使用 `xcodebuild` 创建 **未签名** 的本地 `dist/DevBench.app`。首次打开可能需要从 Xcode 启动；如果要分发给其他用户，需使用自己的 Apple 开发者证书进行 Developer ID 签名和 notarization（公证）。项目 Bundle ID 当前为示例值 `com.example.devbench`，正式发布前需要更换。

> **交付状态：** 本压缩包包含完整 Xcode 工程及源码，而非预编译 `.app`。当前制作环境为 Linux，缺少 Xcode 和 AppKit SDK，**无法进行 macOS GUI 编译或真机运行验收**。已在 Linux Swift 6.2 环境执行自动化检查；在 macOS/Xcode 上运行 `scripts/verify.sh` 将执行真实的 Debug/Release 编译。

## 已实现的 32 个工具

| 类别 | 工具 |
| --- | --- |
| JSON（6） | JSON 格式化与校验、压缩、Key 排序、字符串转义、字符串反转义、树形浏览 |
| 数据转换（7） | JSON → Swift Codable、JSON → CSV、CSV → JSON、JSON → YAML、XML 格式化、XML → JSON、JSON 差异对比 |
| 编码与解码（8） | Base64 编码/解码、URL 编码/解码、HTML 转义/反转义、Unicode 转义/反转义 |
| 哈希与安全（5） | MD5、SHA-256、SHA-512、JWT Header/Payload 解码、UUID v4 生成 |
| 文本处理（5） | 正则匹配、正则替换、大写转换、小写转换、首尾空白和空行整理 |
| 时间（1） | Unix 秒/毫秒 ↔ ISO 8601/本地日期时间 |

### 主界面

- 左侧工具分类与搜索；右侧输入/输出可调整宽度的双栏工作区。
- `⌘ Return` 执行当前工具，支持“载入示例”。
- 支持 UTF-8 本地文本文件导入，结果复制到剪贴板或另存为文件。
- 支持 JSON 对比的第二输入框、正则表达式/替换模板输入框。
- JSON 树形浏览支持对象/数组展开折叠。
- 默认 **不保存操作历史**；用户可主动开启。开启时只在本机 UserDefaults 存储最多 50 条，输入/输出分别最多 25,000 字符；关闭后清空。
- 不进行网络请求、不包含分析 SDK、不上传输入数据、无外部依赖。

## 已知边界

- 这不是 BeJSON 全站 1:1 复刻。**YAML → JSON、JSON → XML、TOML、HTTP/WebSocket 调试、AES/RSA、图片与二维码等尚未开发**。
- JSON → Swift 模型是**基于单份样本的类型推断**；可能需要根据真实接口对可缺失字段、数组元素结构及可空性进行修改。混合类型数组会生成通用 `JSONValue` 枚举。
- JSON → CSV 的嵌套对象、数组输出为 JSON 字符串。CSV → JSON 的列值统一按字符串处理，不隐式推断数值，避免 `0012` 丢失前导零。
- XML → JSON 约定：属性添加 `@` 前缀，混合文本添加 `#text`，重复子元素组成数组。这不是规范化的双向无损转换。
- JSON → YAML 只支持从合法 JSON 生成基础 YAML 1.2 结构，不包括 anchors、tag 等 YAML 特性。
- JWT 只解码 Header/Payload，**不验证签名或 token 有效性**。
- MD5 只能用于兼容旧式校验，**不能用于安全密码存储**。
- 树形浏览为避免无限递归，层级显示上限为 40。文件导入上限 10 MB；大 JSON 的树形浏览仍可能占用较多内存。
- 目前不支持语法高亮、JSONPath、编辑器行号、多个标签页、全局快捷键或工具自动串联。
- 未提供 macOS 签名、公证或 App Store 上架配置。

## 项目结构

```text
DevBench.xcodeproj/             Xcode GUI App 工程
DevBench/
  App/DevBenchApp.swift         应用入口
  Core/                        工具注册、纯数据转换、安全/正则工具
  UI/                          侧栏、双栏编辑器、JSON 树、历史和文件面板
  Assets.xcassets/             原创 App Icon
Tests/CoreSmokeTests.swift      Foundation 逻辑冒烟测试
Tests/GenerateModel.swift      模型输出编译检查所用程序
scripts/build_mac.sh           macOS 编译 .app
scripts/test_core.sh           Swift CLI 冒烟测试
scripts/verify.sh              跨平台测试，macOS 上额外执行 Xcode Debug/Release 构建
.github/workflows/macos-build.yml  GitHub Actions macOS 构建校验
DevBench.xcodeproj/xcshareddata/xcschemes/DevBench.xcscheme  共享 Scheme
scripts/generate_xcodeproj.py  Xcode 工程文件生成器
```

新增工具建议：在 `ToolDefinition.swift` 添加 `ToolID` / 元数据，再到 `ToolEngine.execute` 添加处理分支；必要时将处理算法拆到 `Core/` 单独模块。界面自动按分类显示工具。

## 已执行的检查

在 Linux / Swift 6.2.1 上：

```bash
bash scripts/verify.sh
```

结果：核心冒烟测试 **PASS**、4 组由 JSON → Swift 生成的独立 Swift 模型 typecheck **PASS**、14 份 Swift 源文件语法解析 **PASS**、Xcode `pbxproj` Plist 与共享 Scheme 结构检查 **PASS**。

注意：Linux 不能验证 SwiftUI/AppKit 类型检查及 CryptoKit 摘要执行。工程中已包含 macOS 构建 CI，但交付时尚未运行 macOS runner，CI 结果**未知**。请使用实际的 Xcode 运行 `scripts/verify.sh`，并在发布之前进行 GUI 验收。

## 推荐的后续版本

- **0.2**：JSONPath、JSON Schema、YAML ↔ JSON、TOML ↔ JSON、JSON 转更多语言模型；增加大文件优化。
- **0.3**：语法高亮、编辑器行号、多个 Tab、收藏、组合工作流与批量处理。
- **0.4**：HTTP/GraphQL/WebSocket 调试、请求集合、环境变量与 Secret 存储（Keychain）。
- **0.5**：AES/RSA、文件 hash、二维码、图片工具与签名发行流程。

## 项目说明

本项目为独立开发的示例/首版工具箱。**BeJSON** 是功能设计的参考网站，不包含其网站源码、图片、商标或任何专有资源。
