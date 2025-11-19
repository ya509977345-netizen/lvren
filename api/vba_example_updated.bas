' VBA API调用模块 - 用于Access VBA调用服务器API
' 需要在VBA项目中添加引用：Microsoft XML, v6.0
' 更新版本：适配API改进后的错误处理和速率限制

Option Explicit

' API服务器地址 - 请替换为你的实际服务器地址
Private Const API_BASE_URL As String = "https://lvren.cc/api/"
Private Const API_KEY As String = "Wang869678"

' 全局变量存储用户登录信息
Private g_userToken As String
Private g_userId As Long
Private g_username As String
Private g_balance As Double
Private g_lastRequestTime As Date
Private g_requestCount As Integer

' 错误处理枚举
Public Enum APIError
    Success = 0
    NetworkError = 1
    AuthError = 2
    ServerError = 3
    InvalidResponse = 4
    RateLimitError = 5  ' 新增：速率限制错误
    ValidationError = 6  ' 新增：输入验证错误
End Enum

' 用户信息结构
Public Type UserInfo
    UserId As Long
    Username As String
    Balance As Double
End Type

' 授权信息结构
Public Type LicenseInfo
    LicenseId As Long
    SoftwareId As String
    ExpireDate As Date
    MaxDevices As Integer
    RemainingDays As Integer
    Status As String
End Type

' 充值记录结构
Public Type RechargeRecord
    Amount As Double
    PaymentMethod As String
    RechargeTime As Date
End Type

' ==================== 核心HTTP请求函数 ====================

' 发送HTTP请求（更新版）
Private Function SendHttpRequest(url As String, method As String, Optional data As String = "", Optional contentType As String = "application/json") As String
    On Error GoTo ErrorHandler
    
    ' 检查速率限制（简单客户端限制，避免频繁请求）
    Dim currentTime As Date
    currentTime = Now()
    
    ' 如果同一秒内请求过多，等待一下
    If DateDiff("s", g_lastRequestTime, currentTime) < 1 Then
        Application.Wait DateAdd("s", 1, currentTime)
        currentTime = Now()
    End If
    
    g_lastRequestTime = currentTime
    g_requestCount = g_requestCount + 1
    
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP")
    
    ' 创建HTTP请求
    http.Open method, url, False
    
    ' 设置请求头
    http.setRequestHeader "Content-Type", contentType
    If g_userToken <> "" Then
        http.setRequestHeader "Authorization", "Bearer " & g_userToken
    End If
    http.setRequestHeader "X-API-Key", API_KEY
    
    ' 发送请求
    If method = "POST" Then
        http.send data
    Else
        http.send
    End If
    
    ' 检查速率限制响应头（如果有的话）
    ProcessRateLimitHeaders http
    
    ' 检查响应状态
    Select Case http.Status
        Case 200
            SendHttpRequest = http.responseText
        Case 400
            Err.Raise 1001, "SendHttpRequest", "请求参数错误"
        Case 401
            Err.Raise 1002, "SendHttpRequest", "认证失败"
        Case 403
            Err.Raise 1003, "SendHttpRequest", "权限不足"
        Case 404
            Err.Raise 1004, "SendHttpRequest", "接口不存在"
        Case 429  ' 新增：处理速率限制错误
            Err.Raise 1006, "SendHttpRequest", "请求过于频繁，请稍后再试"
        Case 500
            Err.Raise 1005, "SendHttpRequest", "服务器内部错误"
        Case Else
            Err.Raise 1000, "SendHttpRequest", "HTTP错误: " & http.Status
    End Select
    
    Exit Function
    
ErrorHandler:
    SendHttpRequest = ""
    Debug.Print "HTTP请求错误: " & Err.Description
End Function

' 处理速率限制响应头
Private Sub ProcessRateLimitHeaders(http As Object)
    On Error Resume Next  ' 忽略可能的错误
    
    Dim rateLimit As String
    Dim rateLimitRemaining As String
    Dim rateLimitReset As String
    
    rateLimit = http.getResponseHeader("X-RateLimit-Limit")
    rateLimitRemaining = http.getResponseHeader("X-RateLimit-Remaining")
    rateLimitReset = http.getResponseHeader("X-RateLimit-Reset")
    
    ' 如果获取到了速率限制信息，可以记录到日志中
    If rateLimit <> "" Then
        Debug.Print "速率限制: " & rateLimitRemaining & "/" & rateLimit
    End If
End Sub

' 解析JSON响应（改进版）
Private Function ParseJsonResponse(jsonText As String) As Object
    On Error GoTo ErrorHandler
    
    ' 这里使用简单的JSON解析方法
    ' 如果需要更复杂的JSON解析，可以考虑使用外部库
    Dim result As Object
    Set result = CreateObject("Scripting.Dictionary")
    
    ' 简单的JSON解析（适用于简单结构）
    ' 实际项目中建议使用JSON解析库
    ' 这里仅为示例
    
    ParseJsonResponse = result
    Exit Function
    
ErrorHandler:
    Set ParseJsonResponse = Nothing
    Debug.Print "JSON解析错误: " & Err.Description
End Function

' ==================== 用户认证API ====================

' 用户登录（更新版）
Public Function UserLogin(username As String, password As String) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    ' 构建请求URL和数据
    url = API_BASE_URL & "auth.php?action=login"
    postData = "{""username"":""" & username & """,""password"":""" & password & """}"
    
    ' 发送请求
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        UserLogin = APIError.NetworkError
        Exit Function
    End If
    
    ' 解析响应（简化版）
    If InStr(response, """success"":true") > 0 Then
        ' 提取token
        Dim tokenStart As Integer
        Dim tokenEnd As Integer
        tokenStart = InStr(response, """token"":""") + 9
        tokenEnd = InStr(tokenStart, response, """")
        g_userToken = Mid(response, tokenStart, tokenEnd - tokenStart)
        
        ' 提取用户ID
        tokenStart = InStr(response, """id"":") + 5
        tokenEnd = InStr(tokenStart, response, ",")
        g_userId = Val(Mid(response, tokenStart, tokenEnd - tokenStart))
        
        ' 提取余额
        tokenStart = InStr(response, """balance"":") + 10
        tokenEnd = InStr(tokenStart, response, "}")
        g_balance = Val(Mid(response, tokenStart, tokenEnd - tokenStart))
        
        g_username = username
        
        UserLogin = APIError.Success
    ElseIf InStr(response, """success"":false") > 0 Then
        ' 更详细的错误处理
        If InStr(response, """message"":""用户名或密码错误") > 0 Then
            UserLogin = APIError.AuthError
        ElseIf InStr(response, """message"":""请求过于频繁") > 0 Then
            UserLogin = APIError.RateLimitError
        ElseIf InStr(response, """errors""") > 0 Then
            UserLogin = APIError.ValidationError
        Else
            UserLogin = APIError.ServerError
        End If
    Else
        UserLogin = APIError.InvalidResponse
    End If
    
    Exit Function
    
ErrorHandler:
    Select Case Err.Number
        Case 1002
            UserLogin = APIError.AuthError
        Case 1006
            UserLogin = APIError.RateLimitError
        Case Else
            UserLogin = APIError.ServerError
    End Select
    Debug.Print "登录错误: " & Err.Description
End Function

' 用户注册（更新版）
Public Function UserRegister(username As String, password As String, email As String) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "auth.php?action=register"
    postData = "{""username"":""" & username & """,""password"":""" & password & """,""email"":""" & email & """}"
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        UserRegister = APIError.NetworkError
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        UserRegister = APIError.Success
    ElseIf InStr(response, """success"":false") > 0 Then
        ' 更详细的错误处理
        If InStr(response, """message"":""用户名已存在") > 0 Then
            UserRegister = APIError.AuthError
        ElseIf InStr(response, """message"":""请求过于频繁") > 0 Then
            UserRegister = APIError.RateLimitError
        ElseIf InStr(response, """errors""") > 0 Then
            UserRegister = APIError.ValidationError
        Else
            UserRegister = APIError.ServerError
        End If
    Else
        UserRegister = APIError.InvalidResponse
    End If
    
    Exit Function
    
ErrorHandler:
    Select Case Err.Number
        Case 1006
            UserRegister = APIError.RateLimitError
        Case Else
            UserRegister = APIError.ServerError
    End Select
    Debug.Print "注册错误: " & Err.Description
End Function

' 验证Token（更新版）
Public Function VerifyToken() As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim response As String
    
    url = API_BASE_URL & "auth.php?action=verify"
    response = SendHttpRequest(url, "POST")
    
    If response = "" Then
        VerifyToken = APIError.NetworkError
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        VerifyToken = APIError.Success
    ElseIf InStr(response, """success"":false") > 0 Then
        If InStr(response, """message"":""Token无效或已过期") > 0 Then
            VerifyToken = APIError.AuthError
        ElseIf InStr(response, """message"":""请求过于频繁") > 0 Then
            VerifyToken = APIError.RateLimitError
        Else
            VerifyToken = APIError.ServerError
        End If
    Else
        VerifyToken = APIError.InvalidResponse
    End If
    
    Exit Function
    
ErrorHandler:
    Select Case Err.Number
        Case 1002
            VerifyToken = APIError.AuthError
        Case 1006
            VerifyToken = APIError.RateLimitError
        Case Else
            VerifyToken = APIError.ServerError
    End Select
    Debug.Print "Token验证错误: " & Err.Description
End Function

' ==================== 钱包API ====================

' 获取用户余额（更新版）
Public Function GetUserBalance() As Double
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=balance"
    response = SendHttpRequest(url, "GET")
    
    If response <> "" And InStr(response, """success"":true") > 0 Then
        Dim balanceStart As Integer
        Dim balanceEnd As Integer
        balanceStart = InStr(response, """balance"":") + 10
        balanceEnd = InStr(balanceStart, response, ",")
        GetUserBalance = Val(Mid(response, balanceStart, balanceEnd - balanceStart))
    Else
        GetUserBalance = -1
    End If
    
    Exit Function
    
ErrorHandler:
    GetUserBalance = -1
    Debug.Print "获取余额错误: " & Err.Description
End Function

' 用户充值（更新版）
Public Function UserRecharge(amount As Double, paymentMethod As String) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=recharge"
    postData = "{""amount"":" & amount & ",""payment_method"":""" & paymentMethod & """}"
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        UserRecharge = APIError.NetworkError
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        UserRecharge = APIError.Success
    ElseIf InStr(response, """success"":false") > 0 Then
        If InStr(response, """message"":""请求过于频繁") > 0 Then
            UserRecharge = APIError.RateLimitError
        ElseIf InStr(response, """errors""") > 0 Then
            UserRecharge = APIError.ValidationError
        Else
            UserRecharge = APIError.ServerError
        End If
    Else
        UserRecharge = APIError.InvalidResponse
    End If
    
    Exit Function
    
ErrorHandler:
    Select Case Err.Number
        Case 1006
            UserRecharge = APIError.RateLimitError
        Case Else
            UserRecharge = APIError.ServerError
    End Select
    Debug.Print "充值错误: " & Err.Description
End Function

' 扣费操作（更新版）
Public Function DeductBalance(amount As Double, description As String) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=deduct"
    postData = "{""amount"":" & amount & ",""description"":""" & description & """}"
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        DeductBalance = APIError.NetworkError
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        DeductBalance = APIError.Success
    ElseIf InStr(response, """success"":false") > 0 Then
        If InStr(response, """message"":""请求过于频繁") > 0 Then
            DeductBalance = APIError.RateLimitError
        ElseIf InStr(response, """message"":""余额不足") > 0 Then
            DeductBalance = APIError.AuthError  ' 使用AuthError表示余额不足
        ElseIf InStr(response, """errors""") > 0 Then
            DeductBalance = APIError.ValidationError
        Else
            DeductBalance = APIError.ServerError
        End If
    Else
        DeductBalance = APIError.InvalidResponse
    End If
    
    Exit Function
    
ErrorHandler:
    Select Case Err.Number
        Case 1006
            DeductBalance = APIError.RateLimitError
        Case Else
            DeductBalance = APIError.ServerError
    End Select
    Debug.Print "扣费错误: " & Err.Description
End Function

' ==================== 授权管理API ====================

' 检查软件授权（更新版）
Public Function CheckLicense(softwareId As String) As Boolean
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim response As String
    
    url = API_BASE_URL & "license.php?action=check&software_id=" & softwareId
    response = SendHttpRequest(url, "GET")
    
    If response <> "" And InStr(response, """success"":true") > 0 Then
        CheckLicense = True
    Else
        CheckLicense = False
    End If
    
    Exit Function
    
ErrorHandler:
    CheckLicense = False
    Debug.Print "检查授权错误: " & Err.Description
End Function

' 创建新授权（更新版）
Public Function CreateLicense(softwareId As String, durationDays As Integer, maxDevices As Integer) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "license.php?action=create"
    postData = "{""software_id"":""" & softwareId & """,""duration_days"":" & durationDays & ",""max_devices"":" & maxDevices & "}"
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        CreateLicense = APIError.NetworkError
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        CreateLicense = APIError.Success
    ElseIf InStr(response, """success"":false") > 0 Then
        If InStr(response, """message"":""请求过于频繁") > 0 Then
            CreateLicense = APIError.RateLimitError
        ElseIf InStr(response, """errors""") > 0 Then
            CreateLicense = APIError.ValidationError
        Else
            CreateLicense = APIError.ServerError
        End If
    Else
        CreateLicense = APIError.InvalidResponse
    End If
    
    Exit Function
    
ErrorHandler:
    Select Case Err.Number
        Case 1006
            CreateLicense = APIError.RateLimitError
        Case Else
            CreateLicense = APIError.ServerError
    End Select
    Debug.Print "创建授权错误: " & Err.Description
End Function

' ==================== 工具函数 ====================

' 获取当前用户信息
Public Function GetCurrentUserInfo() As UserInfo
    Dim userInfo As UserInfo
    
    userInfo.UserId = g_userId
    userInfo.Username = g_username
    userInfo.Balance = g_balance
    
    GetCurrentUserInfo = userInfo
End Function

' 检查用户是否已登录
Public Function IsUserLoggedIn() As Boolean
    IsUserLoggedIn = (g_userToken <> "")
End Function

' 用户登出
Public Sub UserLogout()
    g_userToken = ""
    g_userId = 0
    g_username = ""
    g_balance = 0
End Sub

' 测试API连接
Public Function TestAPIConnection() As Boolean
    On Error GoTo ErrorHandler
    
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP")
    
    http.Open "GET", API_BASE_URL & "auth.php?action=verify", False
    http.setRequestHeader "X-API-Key", API_KEY
    http.send
    
    TestAPIConnection = (http.Status = 200 Or http.Status = 401)
    Exit Function
    
ErrorHandler:
    TestAPIConnection = False
End Function

' ==================== 使用示例 ====================

' 示例：完整的登录和授权检查流程（更新版）
Public Sub ExampleUsage()
    Dim result As APIError
    
    ' 1. 测试API连接
    If Not TestAPIConnection() Then
        MsgBox "无法连接到服务器，请检查网络连接", vbCritical
        Exit Sub
    End If
    
    ' 2. 用户登录
    result = UserLogin("testuser", "password123")
    
    Select Case result
        Case APIError.Success
            MsgBox "登录成功！", vbInformation
        Case APIError.AuthError
            MsgBox "用户名或密码错误", vbExclamation
            Exit Sub
        Case APIError.RateLimitError
            MsgBox "请求过于频繁，请稍后再试", vbExclamation
            Exit Sub
        Case APIError.ValidationError
            MsgBox "输入数据格式不正确", vbExclamation
            Exit Sub
        Case Else
            MsgBox "登录失败，请稍后重试", vbCritical
            Exit Sub
    End Select
    
    ' 3. 检查余额
    Dim balance As Double
    balance = GetUserBalance()
    
    If balance >= 0 Then
        MsgBox "当前余额：" & Format(balance, "0.00") & "元", vbInformation
    Else
        MsgBox "获取余额失败", vbExclamation
    End If
    
    ' 4. 检查软件授权
    If CheckLicense("my_software_v1") Then
        MsgBox "软件授权有效", vbInformation
    Else
        MsgBox "软件授权无效或已过期", vbExclamation
    End If
    
    ' 5. 用户登出
    UserLogout
    MsgBox "已登出", vbInformation
End Sub

' 示例：软件功能使用前的授权检查（更新版）
Public Function CheckSoftwareAccess(softwareId As String, featureCost As Double) As Boolean
    ' 检查用户是否登录
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation
        CheckSoftwareAccess = False
        Exit Function
    End If
    
    ' 检查软件授权
    If Not CheckLicense(softwareId) Then
        MsgBox "软件授权无效或已过期", vbExclamation
        CheckSoftwareAccess = False
        Exit Function
    End If
    
    ' 检查余额是否足够
    Dim currentBalance As Double
    currentBalance = GetUserBalance()
    
    If currentBalance < featureCost Then
        MsgBox "余额不足，当前余额：" & Format(currentBalance, "0.00") & "元，需要：" & Format(featureCost, "0.00") & "元", vbExclamation
        CheckSoftwareAccess = False
        Exit Function
    End If
    
    ' 执行扣费
    Dim result As APIError
    result = DeductBalance(featureCost, "使用软件功能")
    
    Select Case result
        Case APIError.Success
            CheckSoftwareAccess = True
            MsgBox "功能使用成功，已扣除费用：" & Format(featureCost, "0.00") & "元", vbInformation
        Case APIError.RateLimitError
            MsgBox "操作过于频繁，请稍后再试", vbExclamation
            CheckSoftwareAccess = False
        Case APIError.AuthError
            MsgBox "余额不足或账户异常", vbExclamation
            CheckSoftwareAccess = False
        Case Else
            MsgBox "功能使用失败，请重试", vbExclamation
            CheckSoftwareAccess = False
    End Select
End Function

' 新增：处理速率限制的辅助函数
Public Sub HandleRateLimitError()
    MsgBox "请求过于频繁，请稍后再试。" & vbCrLf & _
           "服务器限制是为了防止系统滥用，保护您的账户安全。", vbExclamation, "请求限制"
End Sub

' 新增：处理验证错误的辅助函数
Public Sub HandleValidationError()
    MsgBox "输入数据格式不正确，请检查您的输入。" & vbCrLf & _
           "可能的原因：" & vbCrLf & _
           "1. 用户名长度应在3-50个字符之间" & vbCrLf & _
           "2. 密码长度至少6个字符" & vbCrLf & _
           "3. 邮箱格式不正确", vbExclamation, "输入错误"
End Sub