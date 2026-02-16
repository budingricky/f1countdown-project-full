# Codemagic 云编译完整设置指南

本指南详细说明如何在没有 Mac 电脑的情况下，使用 Codemagic 云端编译并自动上传到 TestFlight。

---

## 📋 前提条件

- [x] Apple 开发者账号 ($99/年)
- [x] Git 仓库 (GitHub/GitLab/Bitbucket)
- [x] Codemagic 账号（免费注册）

---

## 🚀 整体流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                     准备工作（一次性）                            │
├─────────────────────────────────────────────────────────────────┤
│  1. Apple Developer 创建 App ID                                  │
│  2. Apple Developer 创建证书 → 导出 .p12 文件                    │
│  3. Apple Developer 创建 Provisioning Profiles → 下载           │
│  4. App Store Connect 创建 API Key → 下载 .p8 文件              │
│  5. App Store Connect 创建应用 → 获取 Apple ID                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   Codemagic 环境变量配置                         │
├─────────────────────────────────────────────────────────────────┤
│  6. 将证书 .p12 转换为 Base64                                    │
│  7. 将 Provisioning Profiles 转换为 Base64                      │
│  8. 在 Codemagic 设置所有环境变量                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      运行构建                                    │
├─────────────────────────────────────────────────────────────────┤
│  9. 推送代码到 Git → 自动触发构建                                │
│  10. Codemagic 自动编译 → 上传 TestFlight                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 第一步：创建 App ID

### 1.1 登录 Apple Developer

访问 [https://developer.apple.com/account](https://developer.apple.com/account)

### 1.2 创建主应用 App ID

1. 点击 **Identifiers** → **+** (添加)
2. 选择 **App IDs** → **Continue**
3. 选择类型：**App** → **Continue**
4. 填写信息：
   - **Description**: `F1Countdown App`
   - **Bundle ID**: `com.f1countdown.app`（Explicit）
5. **Capabilities** 勾选：
   - ✅ App Groups（必需 - 主应用和 Widget 共享数据）
   - ✅ Push Notifications（必需 - 通知功能）
   - ✅ In-App Purchase（必需 - 内购功能）
   - ✅ iCloud（可选 - 如果需要 CloudKit 同步）
   
   > ⚠️ **注意**：CloudKit 不需要单独勾选，它包含在 iCloud 功能中。
   > 如果列表中没有 iCloud 选项，可以跳过，后续在 Xcode 项目中配置。

6. 点击 **Continue** → **Register**

### 1.3 创建 Widget App ID

重复上述步骤，创建 Widget 的 App ID：

- **Description**: `F1Countdown Widget`
- **Bundle ID**: `com.f1countdown.app.widget`
- **Capabilities**: 基础即可，无需特殊权限

> 📝 **关于 CloudKit 的说明**：
> - CloudKit 用于跨设备数据同步，是可选功能
> - 如果暂时不需要同步功能，可以先跳过 iCloud 配置
> - 后续需要时，在 Xcode 项目中添加 iCloud Capability 即可
> - 对于 MVP 版本，App Groups 已经足够实现主应用和 Widget 的数据共享

---

## 第二步：创建证书

### 2.1 在 Windows/Linux 创建证书请求

你需要创建一个 **Certificate Signing Request (CSR)** 文件。

#### 使用 OpenSSL（推荐）

1. 安装 OpenSSL：
   - Windows: 下载 [Win64OpenSSL](https://slproweb.com/products/Win32OpenSSL.html)
   - Linux: `sudo apt install openssl`

2. 打开终端，执行：

```bash
# 生成私钥
openssl genrsa -out private.key 2048

# 创建 CSR 文件
openssl req -new -key private.key -out CertificateSigningRequest.certSigningRequest \
  -subj "/emailAddress=your-email@example.com/CN=Your Name/C=CN"

# 查看 CSR 内容（可选）
openssl req -text -noout -in CertificateSigningRequest.certSigningRequest
```

**重要**：保存好 `private.key` 文件，后续需要用它导出 .p12 证书！

### 2.2 在 Apple Developer 创建证书

1. 访问 [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. 点击 **+** (添加)
3. 选择 **iOS Distribution (App Store and Ad Hoc)** → **Continue**
4. 上传刚才创建的 `CertificateSigningRequest.certSigningRequest`
5. 点击 **Continue** → **Download** 下载证书（`ios_distribution.cer`）

### 2.3 导出 .p12 证书文件

将下载的证书和私钥合并为 .p12 文件：

```bash
# 将 .cer 转换为 .pem
openssl x509 -inform DER -outform PEM -in ios_distribution.cer -out certificate.pem

# 合并为 .p12 文件
openssl pkcs12 -export -out certificate.p12 \
  -inkey private.key \
  -in certificate.pem

# 系统会提示输入密码，请记住这个密码！
# 例如：MyCertPassword123
```

**验证**：确保你有以下文件：
- `certificate.p12` - 证书文件（需要上传到 Codemagic）
- 记住 `.p12` 的密码

---

## 第三步：创建 Provisioning Profiles

### 3.1 创建主应用 Profile

1. 访问 [Apple Developer Profiles](https://developer.apple.com/account/resources/profiles/list)
2. 点击 **+** (添加)
3. 选择 **iOS App Store** → **Continue**
4. 选择 App ID：`com.f1countdown.app`
5. 选择证书：刚才创建的 Distribution 证书
6. 选择设备：无需选择（App Store 分发）
7. **Profile Name**: `F1Countdown_AppStore`
8. 点击 **Download** 下载 `.mobileprovision` 文件

### 3.2 创建 Widget Profile

重复上述步骤：

1. 选择 App ID：`com.f1countdown.app.widget`
2. **Profile Name**: `F1CountdownWidget_AppStore`
3. 下载 `.mobileprovision` 文件

**验证**：确保你有以下文件：
- `F1Countdown_AppStore.mobileprovision` - 主应用 Profile
- `F1CountdownWidget_AppStore.mobileprovision` - Widget Profile

---

## 第四步：创建 App Store Connect API Key

### 4.1 创建 API Key

1. 访问 [App Store Connect - Users and Access](https://appstoreconnect.apple.com/access/integrations/api)
2. 点击 **Request Access**（如果是首次使用）
3. 进入 **Keys** 标签页
4. 点击 **+** (生成新密钥)
5. 填写：
   - **Name**: `Codemagic CI`
   - **Access**: `App Manager`（推荐）
6. 点击 **Generate**
7. **立即下载** `.p8` 文件（只能下载一次！）

### 4.2 记录 API Key 信息

你需要记录以下信息：

| 信息 | 示例 | 说明 |
|------|------|------|
| Key ID | `ABC12DEF34` | 在列表中可见 |
| Issuer ID | `12345678-1234-1234-1234-123456789012` | 页面顶部显示 |
| .p8 文件内容 | `-----BEGIN PRIVATE KEY-----...` | 下载的文件内容 |

---

## 第五步：创建 App Store Connect 应用

### 5.1 创建应用

1. 访问 [App Store Connect - My Apps](https://appstoreconnect.apple.com/apps)
2. 点击 **+** → **New App**
3. 填写信息：
   - **Name**: `下一站：红灯熄灭`
   - **Primary Language**: `Simplified Chinese`
   - **Bundle ID**: 选择 `com.f1countdown.app`
   - **SKU**: `f1countdown2024`
4. 点击 **Create**

### 5.2 获取 Apple ID

创建应用后：

1. 在应用详情页，点击 **App Information**
2. 查看 **Apple ID**（一串数字，如 `1555555551`）
3. **记录这个数字**！

---

## 第六步：将文件转换为 Base64

### 6.1 转换证书文件

**⚠️ 重要：Base64 字符串必须是单行，不能有换行符！**

#### Linux / macOS

```bash
# 方法 1：使用 base64 命令（推荐）
base64 -i certificate.p12 | tr -d '\n'

# 方法 2：使用 openssl
openssl base64 -in certificate.p12 | tr -d '\n'

# 方法 3：一行命令
cat certificate.p12 | base64 | tr -d '\n' && echo
```

#### Windows PowerShell

```powershell
# 读取文件并转换为 Base64（单行输出）
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12")) | Out-File -NoNewline certificate_base64.txt

# 或者直接输出到控制台
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12"))
```

#### Windows Command Prompt

```cmd
# 使用 certutil（需要额外处理换行）
certutil -encode certificate.p12 temp.txt
# 然后手动删除首行、尾行和所有换行符
```

### 6.2 转换 Provisioning Profiles

```bash
# Linux/macOS - 主应用 Profile
base64 -i F1Countdown_AppStore.mobileprovision | tr -d '\n'

# Linux/macOS - Widget Profile
base64 -i F1CountdownWidget_AppStore.mobileprovision | tr -d '\n'

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("F1Countdown_AppStore.mobileprovision"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("F1CountdownWidget_AppStore.mobileprovision"))
```

### 6.3 转换 API Key 文件

**API Key 不需要 Base64，直接使用原始内容即可：**

```bash
# 查看 .p8 文件内容
cat AuthKey_ABC12DEF34.p8
```

复制完整输出，包括：
- `-----BEGIN PRIVATE KEY-----`
- 中间的 Base64 内容（保持原样，可以有多行）
- `-----END PRIVATE KEY-----`

### 6.4 ⚠️ 常见问题

**问题：证书导入失败 "Unknown format"**

**原因**：Base64 字符串包含换行符

**解决**：
1. 确保 Base64 输出是单行（证书和 Profile）
2. 使用 `tr -d '\n'` 删除所有换行符
3. 复制时不要有多余的空格或换行

**验证 Base64 是否正确**：

```bash
# 验证证书 Base64
echo "你的Base64字符串" | base64 -d > test.p12
# 检查文件是否有效
file test.p12
# 应该输出：test.p12: data

# 验证 Profile Base64  
echo "你的Base64字符串" | base64 -d > test.mobileprovision
file test.mobileprovision
# 应该输出：test.mobileprovision: data
```

---

## 第七步：在 Codemagic 创建 Variable Groups

Codemagic 使用 **Variable Groups** 来组织环境变量。你需要创建两个 Group：

### 7.1 登录 Codemagic

访问 [https://codemagic.io](https://codemagic.io) 并登录

### 7.2 添加应用

1. 点击 **Add application**
2. 选择 Git 提供商（GitHub/GitLab/Bitbucket）
3. 授权并选择你的仓库
4. 选择 **Detect configuration file from repository**

### 7.3 创建 Variable Group: `f1countdown_credentials`

这个 Group 包含证书和签名相关的变量。

1. 进入应用 → **Settings** → **Environment variables**
2. 点击 **Add variable group**
3. 输入 Group 名称：`f1countdown_credentials`
4. 添加以下变量：

| 变量名 | 值 | Secure |
|--------|-----|--------|
| `TEAM_ID` | 你的开发者团队 ID（如 `ABC123DEF4`） | ❌ |
| `APP_STORE_APPLE_ID` | 应用的 Apple ID（如 `1555555551`） | ❌ |
| `EMAIL_NOTIFICATION` | 通知邮箱（如 `your@email.com`） | ❌ |
| `CERTIFICATE_BASE64` | certificate.p12 的 Base64 内容 | ✅ **必须勾选** |
| `CERTIFICATE_PASSWORD` | .p12 文件的密码 | ✅ **必须勾选** |
| `PROVISIONING_PROFILE_APP_BASE64` | 主应用 Profile 的 Base64 | ✅ **必须勾选** |
| `PROVISIONING_PROFILE_WIDGET_BASE64` | Widget Profile 的 Base64 | ✅ **必须勾选** |
| `PROVISIONING_PROFILE_NAME_APP` | `F1Countdown_AppStore` | ❌ |
| `PROVISIONING_PROFILE_NAME_WIDGET` | `F1CountdownWidget_AppStore` | ❌ |

5. 点击 **Save** 保存 Group

### 7.4 创建 Variable Group: `appstore_api`

这个 Group 包含 App Store Connect API 相关的变量。

1. 再次点击 **Add variable group**
2. 输入 Group 名称：`appstore_api`
3. 添加以下变量：

| 变量名 | 值 | Secure |
|--------|-----|--------|
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID（如 `ABC12DEF34`） | ❌ |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID | ❌ |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | .p8 文件的完整内容 | ✅ **必须勾选** |

4. 点击 **Save** 保存 Group

### 7.5 ⚠️ 重要提示

**Secure 选项必须勾选！**

对于敏感变量（证书、密码、API Key），务必勾选 **Secure** 选项：

- ✅ 日志中会隐藏这些变量的值
- ✅ 防止敏感信息泄露
- ✅ 符合安全最佳实践

### 7.6 Variable Groups 工作原理

在 `codemagic.yaml` 中，通过以下方式引用 Groups：

```yaml
environment:
  groups:
    - f1countdown_credentials    # 包含证书和签名变量
    - appstore_api               # 包含 API Key 变量
```

Codemagic 会自动将这些 Group 中的变量注入到构建环境中。

---

## 环境变量快速参考

### Group: `f1countdown_credentials`

```
TEAM_ID=你的团队ID
APP_STORE_APPLE_ID=你的应用AppleID
EMAIL_NOTIFICATION=你的邮箱

CERTIFICATE_BASE64=你的证书Base64内容
CERTIFICATE_PASSWORD=你的证书密码

PROVISIONING_PROFILE_APP_BASE64=主应用Profile的Base64
PROVISIONING_PROFILE_WIDGET_BASE64=Widget Profile的Base64
PROVISIONING_PROFILE_NAME_APP=F1Countdown_AppStore
PROVISIONING_PROFILE_NAME_WIDGET=F1CountdownWidget_AppStore
```

### Group: `appstore_api`

```
APP_STORE_CONNECT_API_KEY_ID=你的KeyID
APP_STORE_CONNECT_API_KEY_ISSUER_ID=你的IssuerID
APP_STORE_CONNECT_API_KEY_CONTENT=-----BEGIN PRIVATE KEY-----
你的p8文件内容（多行）
-----END PRIVATE KEY-----
```

---

## 第八步：获取开发者团队 ID

### 方法 1：从 Apple Developer 网站

1. 访问 [Apple Developer Membership](https://developer.apple.com/account/#/membership)
2. 查看 **Team ID**（如 `ABC123DEF4`）

### 方法 2：从证书查看

```bash
# 查看 .p12 证书信息
openssl pkcs12 -in certificate.p12 -nokeys -passin pass:你的密码 | grep "OU="
```

输出类似：`OU=iOS Distribution: Your Name (ABC123DEF4)`

括号中就是 Team ID。

---

## 第九步：运行构建

### 9.1 推送代码到 Git

```bash
# 确保项目中包含 codemagic.yaml 文件
git add codemagic.yaml
git commit -m "chore: add codemagic configuration"
git push origin main
```

### 9.2 在 Codemagic 手动触发构建

1. 进入 Codemagic 应用页面
2. 选择工作流：
   - `ios-dev-workflow` - 验证编译（无需证书）
   - `ios-testflight-workflow` - 完整构建并上传 TestFlight
   - `ios-build-only-workflow` - 仅构建 IPA（不上传）
3. 点击 **Start new build**

### 9.3 查看构建日志

- 点击构建任务查看实时日志
- 如果失败，检查错误信息并修正配置

---

## 第十步：验证 TestFlight 上传

### 10.1 登录 TestFlight

访问 [App Store Connect - TestFlight](https://appstoreconnect.apple.com/apps/你的AppleID/testflight)

### 10.2 检查构建版本

构建成功后，几分钟内应该能看到新版本出现在 TestFlight 中。

---

## 📚 参考资料

### Q: 构建失败提示 "No signing certificate"

**原因**：证书或 Profile 不正确

**解决**：
1. 检查 `CERTIFICATE_BASE64` 是否完整复制
2. 检查 `CERTIFICATE_PASSWORD` 是否正确
3. 检查 Provisioning Profile 是否包含正确的 App ID

### Q: 构建失败提示 "Profile doesn't match"

**原因**：Profile 与 Bundle ID 不匹配

**解决**：
1. 确保 Profile 是为 `com.f1countdown.app` 创建的
2. 确保 Profile 类型是 App Store Distribution
3. 确保 Profile 包含正确的证书

### Q: TestFlight 上传失败

**原因**：API Key 权限不足或配置错误

**解决**：
1. 确保 API Key 有 App Manager 权限
2. 检查 Key ID 和 Issuer ID 是否正确
3. 检查 .p8 文件内容是否完整（包含 BEGIN 和 END 行）

### Q: 如何更新证书？

证书到期前需要：

1. 创建新的 CSR 文件
2. 在 Apple Developer 创建新证书
3. 下载并导出新的 .p12 文件
4. 更新 `CERTIFICATE_BASE64` 环境变量
5. 重新创建所有 Provisioning Profiles
6. 更新 Profile 的 Base64 环境变量

### Q: 构建号冲突怎么办？

Codemagic 会自动获取最新构建号并递增。如果仍有冲突：

1. 在 App Store Connect 手动增加构建号
2. 或者修改 `ios-testflight-workflow` 中的递增逻辑

---

## 📚 参考资料

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Codemagic Documentation](https://docs.codemagic.io/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [OpenSSL Commands](https://www.openssl.org/docs/manmaster/man1/)

---

## ✅ 检查清单

在运行构建前，确认以下事项：

### Apple Developer 准备
- [ ] 已创建 2 个 App ID（主应用 `com.f1countdown.app` + Widget `com.f1countdown.app.widget`）
- [ ] 已创建 iOS Distribution 证书并导出 .p12 文件
- [ ] 已创建 2 个 Provisioning Profiles（App Store Distribution）
- [ ] 已记录 Team ID

### App Store Connect 准备
- [ ] 已创建 App Store Connect API Key（App Manager 权限）
- [ ] 已下载 .p8 文件并记录 Key ID 和 Issuer ID
- [ ] 已在 App Store Connect 创建应用并记录 Apple ID

### 文件转换
- [ ] 已将 .p12 证书转换为 Base64
- [ ] 已将 2 个 Provisioning Profiles 转换为 Base64

### Codemagic 配置
- [ ] 已注册 Codemagic 账号
- [ ] 已添加 Git 仓库
- [ ] 已创建 Variable Group `f1countdown_credentials`（包含所有证书变量）
- [ ] 已创建 Variable Group `appstore_api`（包含 API Key 变量）
- [ ] 敏感变量已勾选 Secure 选项
- [ ] 项目中包含 codemagic.yaml 文件

---

**祝你构建成功！** 🎉
