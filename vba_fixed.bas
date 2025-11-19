' 修复后的VBA API模块
' 解决连接和验证问题

Option Explicit

' 修正的基础设置
Private Const API_BASE_URL As String = "https://lvren.cc/api/"
Private Const API_KEY As String = "Wang869678"

' 全局变量
Private g_userToken As String
Private g_userId As Long
Private g_username As String
Private g_balance As Double

' 错误类型枚举
Public Enum APIError
    Success = 0
    NetworkError = 1
    AuthError = 2
    ServerError = 3
    InvalidResponse = 4
    RateLimitError = 5
    ValidationError = 6
End Enum

' ==================== 核心API函数（修复版） ====================

' 发送HTTP请求（修复版）
Private Function SendHttpRequest(url As String, method As String, Optional data As String = "") As String
    On Error GoTo ErrorHandler
    
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP.6.0")
    
    http.Open method, url, False
    http.setRequestHeader "Content-Type", "application/json"
    http.setRequestHeader "X-API-Key", API_KEY
    If g_userToken <> "" Then
        http.setRequestHeader "Authorization", "Bearer " & g_userToken
    End If
    
    If method = "POST" Then
        http.send data
    Else
        http.send
    End If
    
    Debug.Print "请求URL: " & url
    Debug.Print "请求方法: " & method
    Debug.Print "状态码: " & http.Status
    Debug.Print "响应内容: " & Left(http.responseText, 200) & "..."
    
    ' 检查常见错误状态
    Select Case http.Status
        Case 200
            SendHttpRequest = http.responseText
        Case 400
            ' 处理验证错误
            Debug.Print "验证错误: " & http.responseText
            SendHttpRequest = http.responseText
        Case 401
            Err.Raise 1002, "SendHttpRequest", "认证失败"
        Case 403
            Err.Raise 1003, "SendHttpRequest", "权限不足"
        Case 404
            Err.Raise 1004, "SendHttpRequest", "接口不存在"
        Case 429
            Err.Raise 1006, "SendHttpRequest", "请求过于频繁"
        Case 500
            Err.Raise 1005, "SendHttpRequest", "服务器内部错误"
        Case Else
            Err.Raise 1000, "SendHttpRequest", "HTTP错误: " & http.Status
    End Select
    
    Exit Function
    
ErrorHandler:
    Debug.Print "HTTP请求错误: " & Err.Description
    SendHttpRequest = ""
End Function

' ==================== 用户认证函数（修复版） ====================

' 用户登录（修复版）
Public Function UserLogin(username As String, password As String) As APIError
    On Error GoTo ErrorHandler
    
    ' 输入验证
    If Trim(username) = "" Or Len(username) < 3 Then
        Debug.Print "用户名验证失败: 长度少于3个字符"
        UserLogin = APIError.ValidationError
        Exit Function
    End If
    
    If Trim(password) = "" Or Len(password) < 6 Then
        Debug.Print "密码验证失败: 长度少于6个字符"
        UserLogin = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "auth.php?action=login"
    postData = "{""username"":""" & EscapeJson(username) & """,""password"":""" & EscapeJson(password) & """}"
    
    Debug.Print "登录数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        UserLogin = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "登录响应: " & response
    
    ' 检查是否是验证错误
    If InStr(response, """success"":false") > 0 And InStr(response, """errors""") > 0 Then
        Debug.Print "服务器返回验证错误"
        UserLogin = APIError.ValidationError
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        ' 提取token
        Dim tokenStart As Integer
        Dim tokenEnd As Integer
        tokenStart = InStr(response, """token"":""") + 9
        tokenEnd = InStr(tokenStart, response, """")
        If tokenEnd > tokenStart Then
            g_userToken = Mid(response, tokenStart, tokenEnd - tokenStart)
            Debug.Print "Token提取成功: " & Left(g_userToken, 30) & "..."
        End If
        
        ' 提取用户ID
        tokenStart = InStr(response, """id"":") + 5
        tokenEnd = InStr(tokenStart, response, ",")
        If tokenEnd > tokenStart Then
            g_userId = Val(Mid(response, tokenStart, tokenEnd - tokenStart))
            Debug.Print "用户ID: " & g_userId
        End If
        
        ' 提取余额
        tokenStart = InStr(response, """balance"":") + 10
        tokenEnd = InStr(tokenStart, response, ",")
        If tokenEnd > tokenStart Then
            g_balance = Val(Mid(response, tokenStart, tokenEnd - tokenStart))
            Debug.Print "用户余额: " & g_balance
        End If
        
        g_username = username
        UserLogin = APIError.Success
    Else
        Debug.Print "登录失败: 未知响应格式"
        UserLogin = APIError.AuthError
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "登录错误: " & Err.Description
    UserLogin = APIError.ServerError
End Function

' 用户注册（修复版）
Public Function UserRegister(username As String, password As String, email As String) As APIError
    On Error GoTo ErrorHandler
    
    ' 输入验证
    If Trim(username) = "" Or Len(username) < 3 Or Len(username) > 50 Then
        UserRegister = APIError.ValidationError
        Exit Function
    End If
    
    If Trim(password) = "" Or Len(password) < 6 Or Len(password) > 100 Then
        UserRegister = APIError.ValidationError
        Exit Function
    End If
    
    If Trim(email) = "" Or InStr(email, "@") = 0 Or InStr(email, ".") = 0 Then
        UserRegister = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "auth.php?action=register"
    postData = "{""username"":""" & EscapeJson(username) & """,""password"":""" & EscapeJson(password) & """,""email"":""" & EscapeJson(email) & """}"
    
    Debug.Print "注册数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        UserRegister = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "注册响应: " & response
    
    ' 检查是否是验证错误
    If InStr(response, """success"":false") > 0 And InStr(response, """errors""") > 0 Then
        Debug.Print "服务器返回验证错误"
        UserRegister = APIError.ValidationError
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        UserRegister = APIError.Success
    Else
        UserRegister = APIError.AuthError
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "注册错误: " & Err.Description
    UserRegister = APIError.ServerError
End Function

' 获取用户余额（修复版）
Public Function GetUserBalance() As Double
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        Debug.Print "获取余额失败: 用户未登录"
        GetUserBalance = -1
        Exit Function
    End If
    
    Dim url As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=balance"
    response = SendHttpRequest(url, "GET")
    
    Debug.Print "余额查询响应: " & response
    
    If response <> "" And InStr(response, """success"":true") > 0 Then
        Dim balanceStart As Integer
        Dim balanceEnd As Integer
        balanceStart = InStr(response, """balance"":") + 10
        balanceEnd = InStr(balanceStart, response, ",")
        If balanceEnd > balanceStart Then
            GetUserBalance = Val(Mid(response, balanceStart, balanceEnd - balanceStart))
            g_balance = GetUserBalance ' 更新全局余额
        Else
            GetUserBalance = -1
        End If
    Else
        GetUserBalance = -1
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "获取余额错误: " & Err.Description
    GetUserBalance = -1
End Function

' 充值（修复版）
Public Function UserRecharge(amount As Double, paymentMethod As String) As APIError
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        Debug.Print "充值失败: 用户未登录"
        UserRecharge = APIError.AuthError
        Exit Function
    End If
    
    ' 输入验证
    If amount <= 0 Or amount > 10000 Then
        UserRecharge = APIError.ValidationError
        Exit Function
    End If
    
    If Trim(paymentMethod) = "" Or Len(paymentMethod) > 50 Then
        UserRecharge = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=recharge"
    postData = "{""amount"":" & amount & ",""payment_method"":""" & EscapeJson(paymentMethod) & """}"
    
    Debug.Print "充值数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        UserRecharge = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "充值响应: " & response
    
    ' 检查是否是验证错误
    If InStr(response, """success"":false") > 0 And InStr(response, """errors""") > 0 Then
        Debug.Print "服务器返回验证错误"
        UserRecharge = APIError.ValidationError
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        g_balance = g_balance + amount
        UserRecharge = APIError.Success
    Else
        UserRecharge = APIError.ServerError
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "充值错误: " & Err.Description
    UserRecharge = APIError.ServerError
End Function

' ==================== 辅助函数 ====================

' JSON字符串转义
Private Function EscapeJson(text As String) As String
    ' 简单的JSON转义处理
    EscapeJson = Replace(text, "\", "\\")
    EscapeJson = Replace(EscapeJson, """", "\""")
    EscapeJson = Replace(EscapeJson, vbCrLf, "\n")
    EscapeJson = Replace(EscapeJson, vbCr, "\r")
    EscapeJson = Replace(EscapeJson, vbLf, "\n")
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
    Debug.Print "用户已登出"
End Sub

' 获取当前用户信息
Public Function GetCurrentUserInfo() As String
    If IsUserLoggedIn() Then
        GetCurrentUserInfo = "用户: " & g_username & " (ID: " & g_userId & "), 余额: " & Format(g_balance, "0.00") & " 元"
    Else
        GetCurrentUserInfo = "未登录"
    End If
End Function

' ==================== 简单使用示例（修复版） ====================

' 示例1：登录（修复版）
Public Sub QuickLoginFixed()
    Dim username As String
    Dim password As String
    Dim result As APIError
    
    username = InputBox("请输入用户名:", "登录")
    If username = "" Then Exit Sub
    
    password = InputBox("请输入密码:", "登录")
    If password = "" Then Exit Sub
    
    Debug.Print "尝试登录用户: " & username
    
    result = UserLogin(username, password)
    
    Select Case result
        Case APIError.Success
            MsgBox "登录成功！" & vbCrLf & GetCurrentUserInfo(), vbInformation, "成功"
        Case APIError.AuthError
            MsgBox "用户名或密码错误", vbExclamation, "登录失败"
        Case APIError.ValidationError
            MsgBox "输入验证失败：" & vbCrLf & _
                   "1. 用户名长度应为3-50个字符" & vbCrLf & _
                   "2. 密码长度应为6-100个字符", vbExclamation, "验证失败"
        Case APIError.RateLimitError
            MsgBox "请求过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "登录失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 示例2：测试登录（用于调试）
Public Sub TestLoginWithKnownCredentials()
    ' 使用已知的有效测试凭据
    Dim result As APIError
    
    Debug.Print "使用测试凭据登录..."
    result = UserLogin("testuser", "password123")
    
    Select Case result
        Case APIError.Success
            MsgBox "测试登录成功！" & vbCrLf & GetCurrentUserInfo(), vbInformation, "成功"
        Case APIError.AuthError
            MsgBox "测试登录失败：用户名或密码错误", vbExclamation, "登录失败"
        Case APIError.ValidationError
            MsgBox "测试登录失败：输入验证失败", vbExclamation, "验证失败"
        Case APIError.RateLimitError
            MsgBox "测试登录失败：请求过于频繁", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "测试登录失败：网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "测试登录失败：未知错误", vbExclamation, "未知错误"
    End Select
End Sub

' 示例3：测试API端点
Public Sub TestAPIEndpoints()
    Debug.Print "=== 测试API端点 ==="
    
    ' 1. 测试配置端点
    Debug.Print "1. 测试配置端点..."
    Dim response As String
    response = SendHttpRequest("https://lvren.cc/api/config.php", "GET")
    Debug.Print "配置端点响应长度: " & Len(response)
    
    ' 2. 测试带参数的登录端点
    Debug.Print "2. 测试登录端点（无POST数据）..."
    response = SendHttpRequest("https://lvren.cc/api/auth.php?action=login", "POST", "")
    Debug.Print "登录端点（无数据）响应: " & response
    
    ' 3. 测试有效的登录请求
    Debug.Print "3. 测试有效登录请求..."
    Dim loginData As String
    loginData = "{""username"":""testuser"",""password"":""password123""}"
    response = SendHttpRequest("https://lvren.cc/api/auth.php?action=login", "POST", loginData)
    Debug.Print "登录端点（有效数据）响应: " & response
End Sub

' 示例4：查看余额（修复版）
Public Sub QuickCheckBalanceFixed()
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation, "未登录"
        Exit Sub
    End If
    
    Dim balance As Double
    balance = GetUserBalance()
    
    If balance >= 0 Then
        MsgBox "当前余额: " & Format(balance, "0.00") & " 元", vbInformation, "余额信息"
    Else
        MsgBox "获取余额失败", vbExclamation, "错误"
    End If
End Sub