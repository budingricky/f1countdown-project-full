# Codemagic 环境变量配置指南

## 需要创建的 Variable Groups

在 Codemagic 后台 -> Account settings -> Teams -> Variables 中创建以下两个 Variable Groups：

---

## 1. f1countdown_credentials

包含以下变量：

| 变量名 | 值来源 | 安全 |
|--------|--------|------|
| `CERTIFICATE_BASE64` | p12_b64.txt 内容 | ✅ Secure |
| `CERTIFICATE_PASSWORD` | 123456 | ✅ Secure |
| `PROVISIONING_PROFILE_APP_BASE64` | profile_app_b64.txt 内容 | ✅ Secure |
| `PROVISIONING_PROFILE_WIDGET_BASE64` | profile_widget_b64.txt 内容 | ✅ Secure |
| `TEAM_ID` | XS77QQT3K5 | ❌ Public |

---

## 2. appstore_api

包含以下变量：

| 变量名 | 值 | 安全 |
|--------|-----|------|
| `APP_STORE_CONNECT_API_KEY_ID` | DAZ2L8D5PU | ❌ Public |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | 从 Apple Developer 获取 | ✅ Secure |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | api_key_b64.txt 内容 | ✅ Secure |
| `APP_STORE_APPLE_ID` | 6759248002 | ❌ Public |

### 获取 API Key Issuer ID

1. 登录 [Apple Developer](https://developer.apple.com/account)
2. 进入 Users and Access -> Keys
3. 找到 Key ID 为 DAZ2L8D5PU 的记录
4. 复制 Issuer ID（类似 `69a6deXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` 的 UUID）

---

## 配置步骤

### 步骤 1: 创建 Variable Groups

1. 登录 [Codemagic](https://codemagic.io/)
2. 进入 Account settings -> Teams
3. 选择你的 Team
4. 点击 "Variables" 标签
5. 点击 "Add group" 创建 `f1countdown_credentials`
6. 再创建 `appstore_api` 组

### 步骤 2: 添加变量

在每个组中添加对应的变量：

1. 点击组名进入编辑
2. 点击 "Add variable"
3. 输入变量名和值
4. 勾选 "Secure" 选项（敏感信息）
5. 点击 "Add" 保存

### 步骤 3: 获取 Base64 内容

从 GitHub 仓库下载以下文件并复制内容：
- `p12_b64.txt` -> `CERTIFICATE_BASE64`
- `profile_app_b64.txt` -> `PROVISIONING_PROFILE_APP_BASE64`
- `profile_widget_b64.txt` -> `PROVISIONING_PROFILE_WIDGET_BASE64`
- `api_key_b64.txt` -> `APP_STORE_CONNECT_API_KEY_CONTENT`

---

## 验证配置

配置完成后，触发 `ios-testflight-workflow` 工作流进行测试。

如果仍然报错 "No signing certificate found"，请检查：
1. CERTIFICATE_BASE64 是否正确复制（不要有换行）
2. CERTIFICATE_PASSWORD 是否正确
3. 证书是否过期
4. Team ID 是否匹配

---

## 文件下载链接

- [p12_b64.txt](https://raw.githubusercontent.com/budingricky/f1countdown-project-full/main/p12_b64.txt)
- [profile_app_b64.txt](https://raw.githubusercontent.com/budingricky/f1countdown-project-full/main/profile_app_b64.txt)
- [profile_widget_b64.txt](https://raw.githubusercontent.com/budingricky/f1countdown-project-full/main/profile_widget_b64.txt)
- [api_key_b64.txt](https://raw.githubusercontent.com/budingricky/f1countdown-project-full/main/api_key_b64.txt)
