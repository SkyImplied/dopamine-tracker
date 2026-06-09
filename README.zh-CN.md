<div align="center">
  <img src="./icons/logo_dark.png" alt="FlyMe 图标" width="112">
  <h1>FlyMe · 清醒</h1>
  <p>一款私密、克制且认真设计的 iPhone 自律记录工具。</p>
  <p>
    <img src="https://img.shields.io/badge/platform-iOS%2026%2B-lightgrey?logo=apple" alt="平台 iOS 26+">
    <img src="https://img.shields.io/badge/built%20with-SwiftUI-F05138?logo=swift&logoColor=white" alt="使用 SwiftUI 构建">
    <img src="https://img.shields.io/badge/interface-Liquid%20Glass-8B5CF6" alt="Liquid Glass 界面">
    <img src="https://img.shields.io/badge/data-local%20first-22C55E" alt="本地优先数据">
  </p>
  <p>
    <a href="README.md">English</a> | 简体中文
  </p>
</div>

FlyMe 帮助用户觉察行为、理解自己的节奏，并记录每一次更主动的选择。软件以平静克制的 Liquid Glass 界面，整合快速记录、历史回看、趋势分析与可选的 AI 助手。

## 界面预览

### 首页与 AI 助手

<p align="center">
  <img src="./photos/home-ai-entry.png" alt="包含 AI 助手入口的 FlyMe 首页" width="45%">
  <img src="./photos/ai-assisted-checkin.png" alt="AI 辅助补记确认界面" width="45%">
</p>

首页集中展示当前自律指数、最近记录、快速记录与 AI 助手入口。AI 助手可以总结趋势、给出下一步建议，并将自然语言描述转换成始终需要用户确认的待补记记录。

### 快速记录与 AI 配置

<p align="center">
  <img src="./photos/quick-checkin.png" alt="FlyMe 快速记录界面" width="45%">
  <img src="./photos/ai-settings.png" alt="FlyMe AI 服务设置" width="45%">
</p>

快速记录界面将六类事件收纳在一个专注、清晰的面板中。AI 服务由用户自行配置，API Key 保存在本机 Keychain，是否发送详细分类统计也由用户决定。

### 趋势与指数洞察

<p align="center">
  <img src="./photos/trends.png" alt="指标趋势与范围选择" width="45%">
  <img src="./photos/score-details.png" alt="自律指数计算详情" width="45%">
</p>

可以对比所选行为指标、查看独立得分趋势，并打开指数说明了解当前分数的完整计算方式。

### 历史与设置

<p align="center">
  <img src="./photos/history.png" alt="最近 35 天指标矩阵与日期回看" width="45%">
  <img src="./photos/settings.png" alt="FlyMe 设置界面" width="45%">
</p>

历史页面结合可切换的 35 天指标矩阵、日历回看与记录管理；设置页面集中管理隐私、反馈偏好、手动备份和低调显示。

### Apple Watch 与动感起飞

<p align="center">
  <img src="./photos/现已支持Apple Watch端.png" alt="FlyMe 现已支持 Apple Watch" width="90%">
</p>

<p align="center">
  <img src="./photos/动感起飞功能可以设定目标.png" alt="动感起飞目标设定" width="45%">
  <img src="./photos/动感起飞功能排行榜功能.png" alt="动感起飞排行榜" width="45%">
</p>

<p align="center">
  <img src="./photos/快速记录_Watch.png" alt="Apple Watch 快速记录" width="45%">
  <img src="./photos/同步iPhone端最近记录.png" alt="同步 iPhone 最近记录" width="45%">
</p>

<p align="center">
  <img src="./photos/完整记录_watch.png" alt="Apple Watch 完整记录" width="45%">
  <img src="./photos/watch端独占功能_动感起飞_记录自慰的频率次数和时间.png" alt="Watch 端独占动感起飞" width="45%">
</p>

FlyMe 现已原生支持 Apple Watch，通过 iPhone 与 Watch 之间的无缝连接，快速记录、历史回看与 Watch 端独占的动感起飞功能都可直接在腕上完成。

## AI 助手

- 请求趋势总结与低压力的下一步建议
- 使用自然语言描述过去发生的事件，并在写入前确认 AI 建议记录
- 创建独立对话、回看历史对话并删除不需要的对话
- 配置硅基流动、DeepSeek 或其他 OpenAI 兼容接口
- API Key 仅保存在本机 Keychain，并可选择是否发送详细分类次数

## 快速记录

- 支持记录欲望来袭、成功转移、自慰、房事、看黄和遗精六类事件
- 可以从首页记录此刻，也可以在历史页面补记过去发生的记录
- 每次记录完成后展示独立的全屏成功动效，并播放轻柔音效与触感反馈
- AI 辅助补记始终需要确认后才会写入本机

## 自律指数

- 在首页持续查看根据记录变化的自律指数
- 指数综合考虑近期行为、稳定天数与成功转移次数
- 点击指数即可查看完整的计算逻辑与评分说明
- 通过独立的得分趋势图观察长期变化

## 趋势与统计

- 在同一张趋势图中对比六项指标的发生次数
- 自由勾选需要同时展示的指标
- 支持近一周、近一个月、近半年与近一年范围切换
- 查看不同记录类型的数量分布与整体记录情况

## 历史回看

- 使用中文日期选择器回看过去记录
- 查看任意日期下的完整记录
- 在最近 35 天矩阵中切换六项指标，直观看到每天的发生频率
- 补记过去记录时同样展示完整成功动效
- 集中选择、管理与批量删除历史记录

## 隐私与个性化

- 默认将记录保存在设备本地
- 开启低调显示后，在软件各处隐藏敏感记录名称
- 低调显示覆盖记录、趋势、历史、指数详情、AI 上下文与成功反馈
- 可以分别开启或关闭成功音效与触感反馈
- 支持手动备份与恢复记录，可自行选择 iCloud Drive 等保存位置

## Apple Watch

- 在手表上直接记录六类事件，与 iPhone 体验一致
- 浏览完整历史记录与从 iPhone 同步的近期记录
- 手表首页一键快速记录
- 通过 WatchConnectivity 自动同步 iPhone 端的最近记录
- 专为小屏幕调校的原生 watchOS SwiftUI 界面

## 动感起飞

- 为自慰行为设定个性化频率目标
- 通过动画反馈直观追踪目标进度
- Watch 端独占：直接在 Apple Watch 上记录频率、时长与时间
- 排行榜式排名展示自律追踪成绩
- 所有数据仅保存在本地，在设备间安全同步

## 视觉设计

- 使用原生 SwiftUI 为 iOS 26 构建
- 采用 Liquid Glass、朦胧极光色彩与克制的空间层次
- 包含自然的页面转场、滚动动效与图表切换动画
- App 图标自动适配浅色与深色模式
- 专注于 iPhone 竖屏使用体验
