# macOS 环境配置指南

## 前置要求

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Apple 开发者账号（$99/年）
- iOS 设备（iPhone 14 Pro+ 用于测试灵动岛）

## 步骤 1: 打开项目

```bash
cd /path/to/f1-countdown
open F1Countdown.xcodeproj
```

## 步骤 2: 配置 Bundle Identifier

在 Xcode 中：
1. 选择项目 → Targets → F1Countdown
2. 修改 Bundle Identifier 为你的标识符（如 `com.yourname.f1countdown`）
3. 对所有 Target 重复此操作

## 步骤 3: 配置 Capabilities

### App Groups
1. 选择 Target → Signing & Capabilities
2. 点击 "+ Capability"
3. 添加 "App Groups"
4. 创建 Group: `group.com.yourname.f1countdown`

### CloudKit
1. 添加 "iCloud" capability
2. 勾选 "CloudKit"
3. 创建 Container: `iCloud.com.yourname.f1countdown`

### Push Notifications
1. 添加 "Push Notifications" capability

### Background Modes
1. 添加 "Background Modes" capability
2. 勾选：
   - Background fetch
   - Remote notifications

### In-App Purchase
1. 添加 "In-App Purchase" capability

## 步骤 4: 配置 App Store Connect

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 创建新应用
3. 配置内购产品：
   - 产品 ID: `com.yourname.f1countdown.pro`
   - 类型: Non-Consumable
   - 价格: ¥18

## 步骤 5: 编译验证

```bash
# 编译
xcodebuild -project F1Countdown.xcodeproj \
  -scheme F1Countdown \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# 运行测试
xcodebuild test -project F1Countdown.xcodeproj \
  -scheme F1CountdownTests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 步骤 6: 真机测试

1. 连接 iPhone
2. 在 Xcode 中选择你的设备
3. 运行应用
4. 测试灵动岛功能（需要 iPhone 14 Pro+）

## 步骤 7: 上传 TestFlight

```bash
# Archive
xcodebuild -project F1Countdown.xcodeproj \
  -scheme F1Countdown \
  -archivePath build/F1Countdown.xcarchive \
  archive

# 上传
xcodebuild -exportArchive \
  -archivePath build/F1Countdown.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

## 步骤 8: 提交审核

1. 在 App Store Connect 中选择构建版本
2. 填写元数据（参考 METADATA.md）
3. 提交审核

## 常见问题

### 编译错误
- 确保 iOS Deployment Target 设置为 16.1+
- 清理构建文件夹: Product → Clean Build Folder

### CloudKit 错误
- 确保在开发者账号中启用了 CloudKit
- 检查 Container ID 是否正确

### 内购测试
- 使用 StoreKit 配置文件进行本地测试
- 在沙盒环境中测试购买流程

### 灵动岛不显示
- 确保使用 iPhone 14 Pro 或更新设备
- 检查 Live Activities 权限是否启用
