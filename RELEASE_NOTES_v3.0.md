# FlyMe v3.0

FlyMe v3.0 重点完善 AI 对话阅读体验、Apple Watch 完整性与整体稳定性。

## AI 助手

- AI Markdown 回复现可正确显示加粗、斜体、行内代码和链接。
- 自动将编号与项目符号建议拆分成适合手机阅读的独立段落。
- 优化 AI 回复规范，使建议使用短段落、清晰编号与简短粗体标题。
- Markdown 解析不完整时保留可读的纯文本降级显示。

## Apple Watch

- 修复 Apple Watch 端 App Logo 缺失问题，正确编译并嵌入 Watch AppIcon。
- 补齐 watchOS 所需的图标元数据与资源目录。
- 改进 WatchConnectivity 与 Swift 并发模式的兼容性。

## Bug 修复与稳定性

- 修复 AI 回复正文直接显示 `**` 等 Markdown 标记的问题。
- 修复多个编号建议挤在同一段落、阅读不清晰的问题。
- 完成 iPhone 与 Apple Watch 模拟器构建、安装及启动验证。

## 安装

下载 `FlyMe-v3.0-altstore-unsigned.ipa`，使用 AltStore 安装。AltStore 会在安装过程中对无签名 App 进行签名。

- 应用版本：3.0
- 构建号：3
- 架构：arm64
- 最低系统：iOS 26.0
