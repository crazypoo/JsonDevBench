# DevBench 更新记录

## 0.1.1 · 2026-10-25

- 修复 Xcode/macOS 无法解析 `FoundationXML` 依赖的问题（仅 Linux 平台导入该模块）。
- 修复 `JSONTreeView` 中 `Font.system(size:weight:design:)` 参数顺序错误。
- 增加共享的 `DevBench.xcscheme`，确保 `xcodebuild -scheme DevBench` 指向正确目标。
- 增加跨平台校验脚本 `scripts/verify.sh`；在 macOS 上执行 Debug 与 Release 两次完整构建。
- 新增 GitHub Actions 的 macOS 构建工作流，以便在 macOS runner 上验证完整工程。
- 修正 JSON Key 排序工具的标题副文案。

### 当前验证限制

Linux Swift 6.2.1：核心冒烟测试、四个生成模型 typecheck、所有 Swift 源码语法解析、Xcode 工程与 Scheme 结构检查均通过。没有 macOS/Xcode SDK，无法在当前容器里证明 App 目标实际编译成功。
