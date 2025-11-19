# 乐人软件 API 功能说明

## 🎉 新增功能

### 1. 密码管理功能

#### 修改密码
**API接口：** `POST /api/auth.php?action=change-password`
**需要认证：** 是
**请求参数：**
```json
{
    "old_password": "原密码",
    "new_password": "新密码"
}
```

**VBA函数：** `ChangePassword(oldPassword, newPassword) As APIError`
**UI函数：** `ChangePasswordUI()`

**使用示例（VBA）：**
```vba
Dim result As APIError
result = ChangePassword("oldpass123", "newpass456")
If result = APIError.Success Then
    MsgBox "密码修改成功！"
End If
```

#### 忘记密码
**API接口：** `POST /api/auth.php?action=forgot-password`
**需要认证：** 否
**请求参数：**
```json
{
    "email": "用户邮箱"
}
```

**VBA函数：** `ForgotPassword(email) As APIError`
**UI函数：** `ForgotPasswordUI()`

#### 重置密码
**API接口：** `POST /api/auth.php?action=reset-password`
**需要认证：** 否
**请求参数：**
```json
{
    "token": "重置令牌",
    "password": "新密码"
}
```

**VBA函数：** `ResetPassword(token, newPassword) As APIError`

---

### 2. 软件授权功能

#### 检查软件授权
**API接口：** `GET /api/license.php?action=check&software_id={software_id}`
**需要认证：** 是

**VBA函数：** `CheckLicense(softwareId) As APIError`
**UI函数：** `CheckLicenseUI()`

**使用示例：**
```vba
Dim result As APIError
result = CheckLicense("my_software_001")
If result = APIError.Success Then
    MsgBox "软件授权有效"
Else
    MsgBox "软件授权无效或已过期"
End If
```

#### 获取授权列表
**API接口：** `GET /api/license.php?action=list`
**需要认证：** 是

**VBA函数：** `GetUserLicenses() As String`
**UI函数：** `ViewLicensesUI()`

#### 创建新授权
**API接口：** `POST /api/license.php?action=create`
**需要认证：** 是
**请求参数：**
```json
{
    "software_id": "软件ID",
    "duration_days": 30,
    "max_devices": 1
}
```

**VBA函数：** `CreateLicense(softwareId, durationDays, maxDevices) As APIError`

**使用示例：**
```vba
Dim result As APIError
result = CreateLicense("my_software_001", 30, 1)
If result = APIError.Success Then
    MsgBox "授权创建成功"
End If
```

#### 续期授权
**API接口：** `POST /api/license.php?action=renew`
**需要认证：** 是
**请求参数：**
```json
{
    "license_id": 1,
    "duration_days": 30
}
```

**VBA函数：** `RenewLicense(licenseId, durationDays) As APIError`

#### 禁用授权
**API接口：** `POST /api/license.php?action=disable`
**需要认证：** 是
**请求参数：**
```json
{
    "license_id": 1
}
```

**VBA函数：** `DisableLicense(licenseId) As APIError`

---

## 🔧 数据库更新

### 新增字段
- `users` 表新增字段：
  - `reset_token` VARCHAR(255) NULL - 密码重置令牌
  - `reset_expires` TIMESTAMP NULL - 重置令牌过期时间

---

## 🚀 使用方法

### 在 Access VBA 中使用

1. **导入模块：** 将 `vba_final.bas` 导入到您的 Access 项目中
2. **配置：** 确保 API_BASE_URL 和 API_KEY 正确设置
3. **调用函数：** 使用相应的 UI 函数或直接调用 API 函数

### 基本使用流程

```vba
' 1. 登录
Dim loginResult As APIError
loginResult = UserLogin("your_username", "your_password")

' 2. 检查软件授权
If loginResult = APIError.Success Then
    Dim authResult As APIError
    authResult = CheckLicense("your_software_id")
    
    If authResult = APIError.Success Then
        MsgBox "授权有效，可以使用软件"
    Else
        MsgBox "请购买或续期授权"
    End If
End If

' 3. 修改密码（可选）
ChangePasswordUI

' 4. 查看所有授权（可选）
ViewLicensesUI
```

---

## ⚠️ 注意事项

1. **安全性：** 所有密码相关操作都需要认证
2. **错误处理：** 所有函数都返回 APIError 枚举，请妥善处理错误情况
3. **速率限制：** API 请求有频率限制，请避免过于频繁的调用
4. **Token过期：** 登录 token 1小时后过期，需要重新登录
5. **输入验证：** 所有输入都有验证，请确保参数符合要求

---

## 🎯 完整功能列表

### 用户认证
- ✅ 用户注册
- ✅ 用户登录
- ✅ Token验证
- ✅ **修改密码**（新增）
- ✅ **忘记密码**（新增）
- ✅ **重置密码**（新增）

### 钱包管理
- ✅ 查询余额
- ✅ 充值功能
- ✅ 充值记录

### 软件授权
- ✅ **检查授权**（新增）
- ✅ **获取授权列表**（新增）
- ✅ **创建授权**（新增）
- ✅ **续期授权**（新增）
- ✅ **禁用授权**（新增）

所有功能已完整实现并经过测试，可以直接在您的项目中使用！