# 贡献指南

感谢您有兴趣为 F1 倒计时项目做出贡献！

## 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发环境设置](#开发环境设置)
- [代码风格指南](#代码风格指南)
- [提交消息格式](#提交消息格式)
- [Pull Request 流程](#pull-request-流程)

## 行为准则

本项目采用贡献者公约作为行为准则。参与此项目即表示您同意遵守其条款。请阅读 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) 了解详情。

## 如何贡献

### 报告 Bug

如果您发现了 bug，请通过 [GitHub Issues](../../issues) 提交报告。提交时请包含：

- **标题**：清晰简洁的描述
- **重现步骤**：详细的步骤说明
- **预期行为**：您期望发生什么
- **实际行为**：实际发生了什么
- **环境信息**：iOS 版本、设备型号、应用版本
- **截图**：如果适用，请附上截图

### 建议新功能

我们欢迎新功能建议！请通过 [GitHub Issues](../../issues) 提交，并标记为 `enhancement`。建议应包含：

- **功能描述**：清晰详细的功能说明
- **使用场景**：该功能如何帮助用户
- **可能的实现**：如果您有想法，请分享

### 提交代码

1. Fork 本仓库
2. 创建您的功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 开发环境设置

### 系统要求

- macOS 13.0 或更高版本
- Xcode 14.1 或更高版本
- iOS 16.1 SDK

### 安装步骤

1. 克隆仓库：
   ```bash
   git clone https://github.com/YOUR_USERNAME/f1-countdown.git
   cd f1-countdown
   ```

2. 打开 Xcode 项目：
   ```bash
   open F1Countdown.xcodeproj
   ```

3. 等待 Swift Package Manager 解析依赖

4. 选择目标设备或模拟器，点击运行

## 代码风格指南

### Swift 代码风格

- 遵循 [Swift API 设计指南](https://swift.org/documentation/api-design-guidelines/)
- 使用 4 个空格缩进
- 每行最多 120 个字符
- 使用有意义的变量和函数名

### 命名约定

```swift
// 类和结构体：大驼峰命名
class RaceScheduleViewModel { }
struct RaceInfo { }

// 变量和函数：小驼峰命名
var currentRace: Race?
func updateCountdown() { }

// 常量：小驼峰命名
let defaultTimeout = 30.0

// 枚举：大驼峰命名，成员小驼峰
enum RaceStatus {
    case upcoming
    case live
    case completed
}
```

### SwiftUI 视图组织

```
F1Countdown/
├── Views/           # SwiftUI 视图
│   ├── ContentView.swift
│   └── Components/  # 可复用组件
├── ViewModels/      # 视图模型
├── Models/          # 数据模型
├── Services/        # 网络和数据服务
└── Utils/           # 工具类和扩展
```

### 注释规范

- 使用 Swift 文档注释 (`///`) 为公共 API 编写文档
- 复杂逻辑应添加行内注释说明

```swift
/// 计算到下一场比赛的倒计时
/// - Parameter race: 目标比赛
/// - Returns: 格式化的倒计时字符串
func calculateCountdown(to race: Race) -> String {
    // 实现...
}
```

## 提交消息格式

我们遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

| 类型 | 描述 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 重构（不新增功能或修复 bug） |
| `perf` | 性能优化 |
| `test` | 添加或修改测试 |
| `chore` | 构建过程或辅助工具的变动 |

### 示例

```
feat(countdown): add live race status indicator

- Add real-time race status display
- Implement WebSocket connection for live updates
- Update UI to show current lap and positions

Closes #123
```

## Pull Request 流程

1. **确保测试通过**：在提交 PR 前，请确保所有测试通过

2. **更新文档**：如果您的更改影响 API 或用户界面，请更新相关文档

3. **添加测试**：新功能应包含相应的单元测试

4. **填写 PR 模板**：请完整填写 PR 描述，包括：
   - 更改内容描述
   - 相关 Issue 编号
   - 测试步骤
   - 截图（如适用）

5. **代码审查**：等待维护者审查，及时响应反馈

6. **保持同步**：如果主分支有更新，请及时 rebase

### PR 检查清单

- [ ] 代码遵循项目的代码风格
- [ ] 已进行自我审查
- [ ] 代码有适当的注释
- [ ] 文档已更新
- [ ] 没有引入新的警告
- [ ] 测试已添加/更新并通过
- [ ] 所有现有测试通过

---

再次感谢您的贡献！🏎️
