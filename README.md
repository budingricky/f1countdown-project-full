# F1 倒计时 - "下一站：红灯熄灭"

<div align="center">

🏎️ **为 F1 车迷打造的赛程倒计时应用**

[![Platform](https://img.shields.io/badge/Platform-iOS%2016.1%2B-blue)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

[功能特性](#功能特性) • [安装](#安装) • [技术栈](#技术栈) • [项目结构](#项目结构) • [开发指南](#开发指南)

</div>

---

## 功能特性

### 核心功能

- **赛程倒计时** - 实时显示下一场比赛倒计时，精确到秒
- **完整赛程表** - 包含练习赛、排位赛、冲刺赛和正赛时间
- **赛道图展示** - 液态玻璃风格的精美赛道图（iOS 26+）

### 小组件

- **主屏小组件** - systemSmall、systemMedium、systemLarge 三种尺寸
- **锁屏小组件** - accessoryCircular、accessoryRectangular 两种样式
- **实时更新** - 智能时间线更新策略，省电又及时

### 灵动岛（iPhone 14 Pro+）

- **实时比分** - 比赛进行时显示车手排名
- **锁屏 Live Activity** - 全屏实时比分显示
- **CloudKit Push** - 通过云端推送实时更新

### 通知系统

- **比赛提醒** - 可配置 15/30/60 分钟提前提醒
- **Session 选择** - 自定义提醒哪些比赛环节
- **智能调度** - 自动安排下一场比赛提醒

### Pro 功能

- **锁屏小组件** - 精美的锁屏倒计时组件
- **灵动岛实时比分** - Dynamic Island 实时更新
- **赛道壁纸** - 所有赛道高清壁纸
- **无广告体验** - 享受纯净的使用体验

---

## 安装

### 系统要求

- iOS 16.1 或更高版本
- iPhone 和 iPad 均支持

### 开发环境

```bash
# 克隆仓库
git clone https://github.com/your-username/f1-countdown.git
cd f1-countdown

# 打开项目
open F1Countdown.xcodeproj
```

### 依赖

- 无第三方依赖，全部使用苹果原生框架

---

## 技术栈

### 核心框架

| 框架 | 用途 |
|------|------|
| SwiftUI | UI 框架 |
| SwiftData | 数据持久化 |
| CloudKit | 云端同步 |
| WidgetKit | 小组件 |
| ActivityKit | Live Activities |
| StoreKit 2 | 内购系统 |
| UserNotifications | 本地通知 |

### 架构

```
MVVM 架构
├── Models/          # 数据模型
├── ViewModels/      # 业务逻辑
├── Views/           # 视图层
├── Services/        # 服务层
└── Resources/       # 资源文件
```

### API

使用 [Jolpica-F1](https://jolpica-f1.github.io/jolpica-f1/) 作为数据源（Ergast 继任者）

---

## 项目结构

```
F1Countdown/
├── F1CountdownApp.swift       # App 入口
├── ContentView.swift          # 根视图
│
├── Models/                    # 数据模型
│   ├── Race.swift            # 比赛模型
│   ├── Session.swift         # Session 模型
│   ├── Circuit.swift         # 赛道模型
│   ├── APIResponse.swift     # API 响应模型
│   ├── PersistenceModels.swift  # SwiftData 模型
│   ├── UserPreferences.swift # 用户偏好
│   ├── Product.swift         # 内购产品模型
│   └── LiveActivityAttributes.swift  # Live Activity 属性
│
├── ViewModels/               # 视图模型
│   ├── RaceListViewModel.swift
│   └── RaceDetailViewModel.swift
│
├── Views/                    # 视图层
│   ├── RaceListView.swift   # 赛程列表
│   ├── RaceDetailView.swift # 比赛详情
│   ├── SettingsView.swift   # 设置页面
│   ├── ProView.swift        # Pro 购买页面
│   └── Components/          # 组件
│       ├── CountdownView.swift
│       ├── RaceCardView.swift
│       ├── TrackView.swift
│       ├── LiquidGlassTrackView.swift
│       └── ProBadgeView.swift
│
├── Services/                 # 服务层
│   ├── APIClient.swift      # API 客户端
│   ├── DataService.swift    # 数据服务
│   ├── StoreService.swift   # 内购服务
│   ├── NotificationService.swift  # 通知服务
│   └── LiveActivityService.swift  # Live Activity 服务
│
└── Resources/               # 资源文件
    └── Tracks/              # 赛道数据
        ├── TrackData.swift
        └── CircuitPaths.swift

F1CountdownWidget/           # 小组件 Extension
├── F1CountdownWidget.swift
├── LockScreenWidget.swift
├── F1CountdownWidgetLiveActivity.swift
├── TimelineProvider.swift
└── WidgetAssets.swift

F1CountdownTests/            # 单元测试
├── F1CountdownTests.swift
├── APIClientTests.swift
├── DataServiceTests.swift
├── StoreServiceTests.swift
├── NotificationServiceTests.swift
└── IntegrationTests.swift

F1CountdownUITests/          # UI 测试
├── F1CountdownUITests.swift
└── MainFlowTests.swift
```

---

## 开发指南

### 编译项目

```bash
# 使用 xcodebuild 编译
xcodebuild -project F1Countdown.xcodeproj \
  -scheme F1Countdown \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

### 运行测试

```bash
# 单元测试
xcodebuild test -project F1Countdown.xcodeproj \
  -scheme F1CountdownTests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UI 测试
xcodebuild test -project F1Countdown.xcodeproj \
  -scheme F1CountdownUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### 配置文件

#### App Groups

在 Xcode 中配置 App Groups：

```
group.com.f1countdown.shared
```

用于主应用和小组件之间共享数据。

#### CloudKit

在 Xcode 中配置 CloudKit Container：

```
iCloud.com.f1countdown.app
```

用于数据同步和 Live Activity Push 通知。

#### StoreKit

使用 `Resources/Products.storekit` 配置文件进行本地测试：

```xml
<key>com.f1countdown.pro</key>
<dict>
    <key>Type</key>
    <string>NonConsumable</string>
    <key>Price</key>
    <string>¥18</string>
</dict>
```

### 深度链接

支持以下 URL Scheme：

```
f1countdown://race/{raceId}   # 比赛详情
f1countdown://countdown       # 倒计时视图
f1countdown://schedule        # 赛程表
```

---

## 测试覆盖

### 单元测试

- API 客户端测试
- 数据服务测试
- 内购服务测试
- 通知服务测试
- 集成测试

### UI 测试

- 主界面导航测试
- 比赛详情测试
- 设置页面测试
- Pro 购买流程测试

---

## 发布检查清单

### 必须配置

- [ ] App Groups: `group.com.f1countdown.shared`
- [ ] CloudKit Container: `iCloud.com.f1countdown.app`
- [ ] Push Notifications capability
- [ ] Background Modes: Background fetch, Remote notifications
- [ ] StoreKit 配置文件

### App Store Connect

- [ ] 应用描述和关键词
- [ ] 截图（6.7", 6.5", 5.5"）
- [ ] 隐私政策 URL
- [ ] 内购产品配置
- [ ] 年龄分级

### 测试

- [ ] 所有 XCTest 通过
- [ ] 所有 XCUITest 通过
- [ ] 真机测试（灵动岛功能）
- [ ] TestFlight 内测

---

## 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

### 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试相关
chore: 构建/工具相关
```

---

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 致谢

- [Jolpica-F1](https://jolpica-f1.github.io/jolpica-f1/) - F1 数据 API
- [Formula 1](https://www.formula1.com/) - 官方数据参考
- Apple Developer Documentation

---

<div align="center">

**🏎️ Made with ❤️ for F1 fans**

</div>
