# FlyMe / 清醒

[中文](#中文) · [English](#english)

FlyMe（应用内名称：**清醒**）是一款面向 iOS 26+ 的原生 SwiftUI 私密自律记录应用。它以克制的 Liquid Glass 视觉、趋势统计和本地优先的数据设计，帮助用户觉察习惯、理解频率，并记录每一次更清醒的选择。

> 本项目用于个人习惯记录，不提供医疗诊断、治疗建议或成瘾干预服务。

## 中文

### 功能

- 六类快速记录：欲望来袭、成功转移、自慰、房事、看黄、遗精
- 每次记录后的全屏成功动效、独立提示音和触感反馈
- 基于近 7 天行为、稳定天数与成功转移记录计算自律指数
- 六项指标次数趋势，可查看近一周、近一个月、近半年与近一年
- 独立的自律得分趋势图与评分算法说明
- 最近 35 天单项指标矩阵，支持六类指标快速切换
- 按日期查看、补记过去记录及批量管理与删除
- 低调显示模式，隐藏敏感记录名称
- 手动导出和恢复 JSON 备份，可保存到私人 iCloud Drive
- 原生 iOS 26 Liquid Glass、动态渐变与滚动动效
- 仅支持 iPhone 竖屏

### 隐私

- 记录默认仅保存在设备本地的 `UserDefaults` 中。
- 应用不要求账号，也不会自动上传记录。
- iCloud Drive 仅用于用户主动选择的手动备份与恢复。
- `data/` 和备份文件已被 Git 忽略，避免私人记录被提交。

### 环境要求

- iOS 26.0+
- Xcode 26+
- Swift 6
- iPhone

### 构建

1. 克隆仓库：

   ```bash
   git clone https://github.com/SkyImplied/dopamine-tracker.git
   cd dopamine-tracker
   ```

2. 使用 Xcode 打开 `FlyMe.xcodeproj`。
3. 在 **Signing & Capabilities** 中选择你自己的开发团队，并按需修改 Bundle Identifier。
4. 选择 iPhone 模拟器或已连接的 iPhone，然后运行。

使用免费 Apple ID 安装到真机时，签名通常需要每 7 天重新安装一次。长期自用可以通过 Xcode、AltStore 或 SideStore 定期续签。

### 数据备份格式

应用可导入和导出 JSON 数组，每条记录包含：

```json
{
  "id": "UUID",
  "kind": "masturbation",
  "date": 801619200,
  "note": ""
}
```

支持的 `kind` 值：

`urge`、`redirected`、`masturbation`、`intimacy`、`explicitContent`、`nocturnalEmission`

---

## English

FlyMe, displayed in-app as **清醒**, is a private self-awareness and habit-tracking app built natively with SwiftUI for iOS 26+. Its restrained Liquid Glass interface, local-first data model, and clear statistics help users understand behavioral patterns and recognize more intentional choices.

> This project is a personal habit tracker. It does not provide medical diagnosis, treatment advice, or addiction intervention.

### Features

- Six quick-entry categories: urge, successful redirection, masturbation, intimacy, explicit content, and nocturnal emission
- Full-screen success animations with distinct sound effects and haptic feedback
- A self-discipline score based on recent behavior, stable days, and successful redirections
- Count-based trends for all six metrics across one week, one month, six months, or one year
- A separate score trend chart with an explanation of the scoring model
- A switchable 35-day metric matrix for each category
- Date-based history browsing, backdated entries, and bulk record deletion
- Discreet mode that hides sensitive category names
- Manual JSON backup and restore, including user-selected iCloud Drive locations
- Native iOS 26 Liquid Glass, animated gradients, and scroll-driven motion
- Portrait-only iPhone interface

### Privacy

- Records are stored locally in `UserDefaults` by default.
- The app requires no account and does not automatically upload records.
- iCloud Drive is only used when the user manually exports or restores a backup.
- The repository ignores `data/` and backup files to prevent personal records from being committed.

### Requirements

- iOS 26.0+
- Xcode 26+
- Swift 6
- iPhone

### Build

1. Clone the repository:

   ```bash
   git clone https://github.com/SkyImplied/dopamine-tracker.git
   cd dopamine-tracker
   ```

2. Open `FlyMe.xcodeproj` in Xcode.
3. Select your own development team under **Signing & Capabilities** and change the Bundle Identifier if needed.
4. Select an iPhone Simulator or a connected iPhone, then run the app.

Apps installed on a physical device with a free Apple ID usually need to be re-signed every seven days. For long-term personal use, Xcode, AltStore, or SideStore can be used for periodic re-signing.

### Backup Format

The app imports and exports a JSON array. Each record contains:

```json
{
  "id": "UUID",
  "kind": "masturbation",
  "date": 801619200,
  "note": ""
}
```

Supported `kind` values:

`urge`, `redirected`, `masturbation`, `intimacy`, `explicitContent`, `nocturnalEmission`

## Project Structure

```text
FlyMe/
├── FlyMeApp.swift    # App entry point and shared store
├── Models.swift      # Data models, scoring, trends, persistence, backup
├── RootView.swift    # Main screens and user flows
├── Visuals.swift     # Reusable visual effects and success animation
└── Assets.xcassets   # App icons and visual assets
```

## Technology

- SwiftUI
- Swift Observation
- Swift Charts
- AVFoundation
- Uniform Type Identifiers / FileDocument
- iOS 26 Liquid Glass APIs
