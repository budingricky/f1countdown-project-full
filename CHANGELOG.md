# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Widget support for iOS home screen
- Dark mode optimization

## [1.0.0] - 2026-02-16

### Added

- **核心功能**
  - 2026赛季F1赛历完整展示（24场比赛）
  - 实时倒计时显示（天、时、分、秒）
  - 赛事详情查看（赛道信息、比赛时间）
  
- **用户界面**
  - 现代化 SwiftUI 界面设计
  - 支持深色/浅色模式自动切换
  - 流畅的动画和过渡效果
  - 自定义 F1 主题配色

- **小组件**
  - 主屏幕小组件支持
  - 显示下一场比赛倒计时
  - 小、中、大三种尺寸

- **数据管理**
  - 本地数据缓存
  - 离线模式支持
  - 赛程自动更新

- **赛事信息**
  - 各大奖赛详细信息
  - 赛道布局图展示
  - 比赛时间时区自动转换

### Technical

- iOS 16.1+ 支持
- SwiftUI 框架
- MVVM 架构模式
- 单元测试和 UI 测试覆盖

---

## 版本命名规则

- **主版本号 (MAJOR)**：不兼容的 API 变更
- **次版本号 (MINOR)**：向后兼容的功能新增
- **修订号 (PATCH)**：向后兼容的问题修复

## 变更类型

- `Added` - 新功能
- `Changed` - 现有功能的变更
- `Deprecated` - 即将废弃的功能
- `Removed` - 已移除的功能
- `Fixed` - Bug 修复
- `Security` - 安全相关的修复

[Unreleased]: https://github.com/username/f1-countdown/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/username/f1-countdown/releases/tag/v1.0.0
