# Access VBA API集成指南

本指南详细介绍如何在Microsoft Access应用程序中集成乐人软件API，实现用户认证、钱包管理和功能使用等功能。

## 目录

1. [准备工作](#准备工作)
2. [基础集成](#基础集成)
3. [快速入门](#快速入门)
4. [高级应用](#高级应用)
5. [最佳实践](#最佳实践)
6. [常见问题](#常见问题)

## 准备工作

### 1. 添加必要的引用

在Access VBA编辑器中，需要添加以下引用：

1. 打开VBA编辑器（Alt+F11）
2. 选择"工具" → "引用"
3. 勾选以下项目：
   - Microsoft XML, v6.0
   - Microsoft Scripting Runtime (用于JSON处理)

### 2. 导入API模块

将以下模块导入到您的Access项目中：

- `vba_quickstart.bas` - 基础API功能和快速入门示例
- `vba_access_examples.bas` - 完整的应用程序集成示例

### 3. 创建基础表结构

为了记录用户活动和本地数据，建议创建以下表：

```sql
-- 用户活动日志表
CREATE TABLE UserActivityLog (
    ID AUTOINCREMENT PRIMARY KEY,
    UserID LONG,
    Action TEXT(50),
    Description MEMO,
    LogTime DATETIME DEFAULT NOW()
);

-- 功能使用记录表
CREATE TABLE FeatureUsageLog (
    ID AUTOINCREMENT PRIMARY KEY,
    UserID LONG,
    FeatureName TEXT(50),
    Cost CURRENCY,
    UsageTime DATETIME DEFAULT NOW()
);
```

## 基础集成

### 1. 登录窗体

创建一个登录窗体，包含以下控件：

| 控件名称 | 类型 | 说明 |
|---------|------|------|
| txtUsername | 文本框 | 用户名输入 |
| txtPassword | 文本框 | 密码输入（输入掩码：密码） |
| btnLogin | 命令按钮 | 登录按钮 |
| btnRegister | 命令按钮 | 注册按钮 |
| lblStatus | 标签 | 显示状态信息 |
| chkRememberMe | 复选框 | 记住登录状态 |

将以下代码添加到窗体模块：

```vba
Private Sub btnLogin_Click()
    LoginUser Me.txtUsername, Me.txtPassword, Me.lblStatus
    
    If Me.chkRememberMe And IsUserLoggedIn() Then
        SaveSetting "MyApp", "Auth", "Token", g_userToken
        SaveSetting "MyApp", "Auth", "Username", g_username
    End If
End Sub

Private Sub btnRegister_Click()
    DoCmd.OpenForm "frmRegister", acNormal, , , , acDialog
End Sub

Private Sub Form_Load()
    ' 尝试自动登录
    Dim savedToken As String
    savedToken = GetSetting("MyApp", "Auth", "Token", "")
    
    If savedToken <> "" Then
        g_userToken = savedToken
        If VerifyToken() = APIError.Success Then
            g_username = GetSetting("MyApp", "Auth", "Username", "")
            Me.lblStatus.Caption = "已自动登录: " & g_username
            ' 打开主窗体
            DoCmd.OpenForm "frmMain"
            DoCmd.Close acForm, Me.Name
        Else
            DeleteSetting "MyApp", "Auth", "Token"
            DeleteSetting "MyApp", "Auth", "Username"
        End If
    End If
End Sub
```

### 2. 主窗体

创建一个主窗体，包含用户信息显示和功能按钮：

| 控件名称 | 类型 | 说明 |
|---------|------|------|
| lblUserInfo | 标签 | 显示当前用户信息 |
| lblBalance | 标签 | 显示当前余额 |
| btnRefresh | 命令按钮 | 刷新用户信息和余额 |
| btnRecharge | 命令按钮 | 充值按钮 |
| btnFeature1 | 命令按钮 | 功能1按钮 |
| btnFeature2 | 命令按钮 | 功能2按钮 |
| btnLogout | 命令按钮 | 登出按钮 |

将以下代码添加到窗体模块：

```vba
Private Sub Form_Load()
    UpdateUserStatusDisplay Me.lblUserInfo, Me.lblBalance, Me.btnRecharge
End Sub

Private Sub btnRefresh_Click()
    UpdateUserStatusDisplay Me.lblUserInfo, Me.lblBalance, Me.btnRecharge
End Sub

Private Sub btnRecharge_Click()
    If ShowRechargeDialog() Then
        UpdateUserStatusDisplay Me.lblUserInfo, Me.lblBalance, Me.btnRecharge
    End If
End Sub

Private Sub btnFeature1_Click()
    If UseSoftwareFeature("数据分析", 10.0) Then
        MsgBox "数据分析功能已执行", vbInformation, "功能完成"
    End If
End Sub

Private Sub btnFeature2_Click()
    If UseSoftwareFeature("报告生成", 5.0) Then
        MsgBox "报告生成功能已执行", vbInformation, "功能完成"
    End If
End Sub

Private Sub btnLogout_Click()
    UserLogout
    DeleteSetting "MyApp", "Auth", "Token"
    DeleteSetting "MyApp", "Auth", "Username"
    DoCmd.Close acForm, Me.Name
    DoCmd.OpenForm "frmLogin"
End Sub
```

## 快速入门

如果您想快速开始，可以使用以下简化方法：

1. **导入模块**：将`vba_quickstart.bas`导入到您的Access项目中
2. **创建测试窗体**：创建一个简单的窗体，添加几个按钮
3. **绑定事件**：将按钮的Click事件绑定到相应的函数上

例如，创建一个测试窗体，添加以下按钮和事件：

```vba
Private Sub btnTestLogin_Click()
    Call QuickLogin
End Sub

Private Sub btnTestBalance_Click()
    Call QuickCheckBalance
End Sub

Private Sub btnTestRecharge_Click()
    Call QuickRecharge
End Sub

Private Sub btnTestFeature_Click()
    Call QuickUseFeature
End Sub
```

## 高级应用

### 1. 定时更新余额

可以在应用程序中添加定时器，定期更新用户余额：

```vba
Private Sub Form_Timer()
    ' 每5分钟更新一次余额
    If IsUserLoggedIn() Then
        AutoUpdateBalance 5
    End If
End Sub

Private Sub Form_Load()
    Me.TimerInterval = 300000 ' 5分钟（毫秒）
End Sub
```

### 2. 数据库记录集成

将API使用与本地数据库记录结合：

```vba
' 使用功能时记录到本地数据库
Public Sub UseFeatureWithLogging(featureName As String, cost As Double)
    If UseSoftwareFeature(featureName, cost) Then
        ' 记录到本地表
        Dim db As Database
        Dim rs As Recordset
        
        Set db = CurrentDb()
        Set rs = db.OpenRecordset("FeatureUsageLog", dbOpenDynaset)
        
        rs.AddNew
        rs!UserID = g_userId
        rs!FeatureName = featureName
        rs!Cost = cost
        rs.Update
        
        rs.Close
        db.Close
    End If
End Sub
```

### 3. 错误处理和日志记录

实现完善的错误处理和日志记录：

```vba
Private Sub LogAPIActivity(action As String, result As APIError, Optional details As String = "")
    On Error Resume Next
    
    Dim db As Database
    Dim rs As Recordset
    
    Set db = CurrentDb()
    Set rs = db.OpenRecordset("APIActivityLog", dbOpenDynaset)
    
    rs.AddNew
    rs!UserID = g_userId
    rs!Action = action
    rs!Result = GetResultText(result)
    rs!Details = details
    rs!LogTime = Now()
    rs.Update
    
    rs.Close
    db.Close
End Function

Private Function GetResultText(result As APIError) As String
    Select Case result
        Case APIError.Success: GetResultText = "成功"
        Case APIError.NetworkError: GetResultText = "网络错误"
        Case APIError.AuthError: GetResultText = "认证失败"
        Case APIError.ServerError: GetResultText = "服务器错误"
        Case APIError.RateLimitError: GetResultText = "请求限制"
        Case APIError.ValidationError: GetResultText = "验证错误"
        Case Else: GetResultText = "未知错误"
    End Select
End Function
```

## 最佳实践

1. **错误处理**：始终使用适当的错误处理，特别是在网络请求中
2. **用户体验**：提供清晰的状态反馈，特别是在长时间操作时
3. **安全考虑**：不要在代码中硬编码敏感信息，使用安全的存储方式
4. **性能优化**：合理使用速率限制，避免频繁请求
5. **日志记录**：记录重要操作，便于问题排查和审计

## 常见问题

### Q1: 如何处理网络连接问题？
A1: 使用Try-Catch错误处理，提供友好的错误消息和重试机制。

### Q2: 如何保存用户登录状态？
A2: 可以使用Access的SaveSetting/GetSetting函数或加密的本地文件存储Token。

### Q3: 如何处理API更新？
A3: 版本控制您的API调用代码，定期检查API变更通知。

### Q4: 如何提高安全性？
A4: 实施客户端输入验证，定期更新Token，使用HTTPS连接。

### Q5: 如何处理大量数据？
A5: 考虑使用分页和批量操作，优化网络请求。

## 示例项目

完整的示例项目可以在以下位置找到：
- `vba_access_examples.bas` - 完整的应用程序集成示例
- `vba_quickstart.bas` - 快速入门示例

这些示例包含了所有常见的API使用场景，可以作为您开发的起点。