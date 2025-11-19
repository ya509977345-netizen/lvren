' 最终修复版VBA API模块
' 解决用户认证问题

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

' ==================== 核心API函数（最终版） ====================

' 发送HTTP请求（使用WinHttp替代XMLHTTP）
Private Function SendHttpRequest(url As String, method As String, Optional data As String = "") As String
    On Error GoTo ErrorHandler
    
    ' 首先尝试使用WinHttp
    Dim winHttpResult As String
    winHttpResult = UseWinHttpRequest(url, method, data)
    
    If winHttpResult <> "" Then
        SendHttpRequest = winHttpResult
        Exit Function
    End If
    
    ' 如果WinHttp失败，回退到XMLHTTP
    Debug.Print "回退到XMLHTTP方法"
    SendHttpRequest = UseXMLHttpRequest(url, method, data)
    
    Exit Function
    
ErrorHandler:
    Debug.Print "HTTP请求错误: " & Err.Description
    SendHttpRequest = ""
End Function

' 使用WinHttp对象的HTTP请求方法
Private Function UseWinHttpRequest(url As String, method As String, Optional data As String = "") As String
    On Error GoTo ErrorHandler
    
    Dim http As Object
    Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
    
    http.Open method, url, False
    http.setRequestHeader "Content-Type", "application/json"
    http.setRequestHeader "X-API-Key", API_KEY
    If g_userToken <> "" Then
        http.setRequestHeader "Authorization", "Bearer " & g_userToken
        Debug.Print "设置Authorization头 (WinHttp): Bearer " & Left(g_userToken, 30) & "..."
    End If
    
    ' 添加更多请求头来模拟curl
    http.setRequestHeader "User-Agent", "curl/7.68.0"
    http.setRequestHeader "Accept", "application/json"
    http.setRequestHeader "Cache-Control", "no-cache"
    
    Debug.Print "=== WinHttp请求调试 ==="
    Debug.Print "请求URL: " & url
    Debug.Print "请求方法: " & method
    
    If method = "POST" Then
        http.send data
    Else
        http.send
    End If
    
    Debug.Print "状态码: " & http.Status
    
    ' 获取所有响应头进行调试
    Debug.Print "=== 响应头调试 (WinHttp) ==="
    Debug.Print "完整响应头: " & http.getAllResponseHeaders()
    Debug.Print "=== 响应头结束 ==="
    
    ' 检查常见错误状态
    Select Case http.Status
        Case 200
            Debug.Print "响应长度: " & Len(http.responseText)
            Debug.Print "完整响应: " & http.responseText
            Debug.Print "响应前100字符: " & Left(http.responseText, 100)
            UseWinHttpRequest = http.responseText
        Case 400
            Debug.Print "验证错误: " & http.responseText
            UseWinHttpRequest = http.responseText
        Case 401
            Debug.Print "认证失败: " & http.responseText
            Err.Raise 1002, "UseWinHttpRequest", "认证失败"
        Case 403
            Err.Raise 1003, "UseWinHttpRequest", "权限不足"
        Case 404
            Err.Raise 1004, "UseWinHttpRequest", "接口不存在"
        Case 429
            Err.Raise 1006, "UseWinHttpRequest", "请求过于频繁"
        Case 500
            Err.Raise 1005, "UseWinHttpRequest", "服务器内部错误"
        Case Else
            Err.Raise 1000, "UseWinHttpRequest", "HTTP错误: " & http.Status
            UseWinHttpRequest = ""
    End Select
    
    Exit Function
    
ErrorHandler:
    Debug.Print "WinHttp请求错误: " & Err.Description
    UseWinHttpRequest = ""
End Function

' 使用XMLHTTP的备用方法
Private Function UseXMLHttpRequest(url As String, method As String, Optional data As String = "") As String
    On Error GoTo ErrorHandler
    
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP.6.0")
    
    http.Open method, url, False
    http.setRequestHeader "Content-Type", "application/json"
    http.setRequestHeader "X-API-Key", API_KEY
    If g_userToken <> "" Then
        http.setRequestHeader "Authorization", "Bearer " & g_userToken
        Debug.Print "设置Authorization头 (XMLHTTP): Bearer " & Left(g_userToken, 30) & "..."
    End If
    
    ' 添加更多请求头来模拟curl
    http.setRequestHeader "User-Agent", "curl/7.68.0"
    http.setRequestHeader "Accept", "application/json"
    http.setRequestHeader "Cache-Control", "no-cache"
    
    If method = "POST" Then
        http.send data
    Else
        http.send
    End If
    
    Debug.Print "=== XMLHTTP请求调试 ==="
    Debug.Print "状态码: " & http.Status
    
    ' 获取所有响应头进行调试
    Debug.Print "=== 响应头调试 (XMLHTTP) ==="
    Debug.Print "完整响应头: " & http.getAllResponseHeaders()
    Debug.Print "=== 响应头结束 ==="
    
    ' 检查常见错误状态
    Select Case http.Status
        Case 200
            Debug.Print "响应长度: " & Len(http.responseText)
            Debug.Print "完整响应: " & http.responseText
            UseXMLHttpRequest = http.responseText
        Case 400
            Debug.Print "验证错误: " & http.responseText
            UseXMLHttpRequest = http.responseText
        Case 401
            Debug.Print "认证失败: " & http.responseText
            Err.Raise 1002, "UseXMLHttpRequest", "认证失败"
        Case 403
            Err.Raise 1003, "UseXMLHttpRequest", "权限不足"
        Case 404
            Err.Raise 1004, "UseXMLHttpRequest", "接口不存在"
        Case 429
            Err.Raise 1006, "UseXMLHttpRequest", "请求过于频繁"
        Case 500
            Err.Raise 1005, "UseXMLHttpRequest", "服务器内部错误"
        Case Else
            Err.Raise 1000, "UseXMLHttpRequest", "HTTP错误: " & http.Status
            UseXMLHttpRequest = ""
    End Select
    
    Exit Function
    
ErrorHandler:
    Debug.Print "XMLHTTP请求错误: " & Err.Description
    UseXMLHttpRequest = ""
End Function

' ==================== 用户认证函数（最终版） ====================

' 用户注册
Public Function UserRegister(username As String, password As String, email As String) As APIError
    On Error GoTo ErrorHandler
    
    ' 输入验证
    If Trim(username) = "" Or Len(username) < 3 Or Len(username) > 50 Then
        Debug.Print "用户名验证失败"
        UserRegister = APIError.ValidationError
        Exit Function
    End If
    
    If Trim(password) = "" Or Len(password) < 6 Or Len(password) > 100 Then
        Debug.Print "密码验证失败"
        UserRegister = APIError.ValidationError
        Exit Function
    End If
    
    If Trim(email) = "" Or InStr(email, "@") = 0 Or InStr(email, ".") = 0 Then
        Debug.Print "邮箱验证失败"
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
        Debug.Print "注册成功"
    Else
        UserRegister = APIError.AuthError
        Debug.Print "注册失败"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "注册错误: " & Err.Description
    UserRegister = APIError.ServerError
End Function

' 用户登录（最终版）
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
        
        ' 提取用户ID和余额 - 更精确的解析方法
        Dim userStart As Integer
        userStart = InStr(response, """user"":{") + 7
        
        ' 提取ID
        tokenStart = InStr(userStart, response, """id"":") + 6
        tokenEnd = InStr(tokenStart, response, """")
        If tokenEnd > tokenStart Then
            g_userId = Val(Mid(response, tokenStart, tokenEnd - tokenStart))
            Debug.Print "用户ID: " & g_userId
        End If
        
        ' 提取余额
        tokenStart = InStr(userStart, response, """balance"":") + 11
        tokenEnd = InStr(tokenStart, response, """")
        If tokenEnd > tokenStart Then
            g_balance = Val(Mid(response, tokenStart, tokenEnd - tokenStart))
            Debug.Print "用户余额: " & g_balance
        End If
        
        g_username = username
        UserLogin = APIError.Success
        Debug.Print "登录成功"
    Else
        Debug.Print "登录失败: 用户名或密码错误"
        UserLogin = APIError.AuthError
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "登录错误: " & Err.Description
    UserLogin = APIError.ServerError
End Function

' 获取用户余额（最终版）
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
        ' 检查是否有调试信息
        Dim hasDebug As Boolean
        hasDebug = (InStr(response, """debug_balance""") > 0)
        
        If hasDebug Then
            Debug.Print "检测到调试信息，优先解析debug_balance字段"
            Dim debugBalanceStart As Integer
            Dim debugBalanceEnd As Integer
            debugBalanceStart = InStr(response, """debug_balance"":") + 16
            
            ' 查找调试字段的结束位置
            debugBalanceEnd = InStr(debugBalanceStart, response, "}")
            If debugBalanceEnd = 0 Then debugBalanceEnd = InStr(debugBalanceStart, response, ",")
            
            If debugBalanceEnd > debugBalanceStart Then
                Dim debugBalance As String
                debugBalance = Mid(response, debugBalanceStart, debugBalanceEnd - debugBalanceStart)
                GetUserBalance = Val(debugBalance)
                Debug.Print "调试字段解析，余额: " & GetUserBalance
            End If
        Else
            ' 标准解析逻辑
            Dim balanceStart As Integer
            Dim balanceEnd As Integer
            balanceStart = InStr(response, """balance"":") + 10
            
            ' 首先尝试标准格式（有逗号）
            balanceEnd = InStr(balanceStart, response, ",")
            
            If balanceEnd > balanceStart Then
                ' 标准JSON格式
                GetUserBalance = Val(Mid(response, balanceStart, balanceEnd - balanceStart))
                Debug.Print "标准格式解析，余额: " & GetUserBalance
            Else
                ' 尝试无逗号格式或引号结束
                balanceEnd = InStr(balanceStart, response, """")
                If balanceEnd > balanceStart Then
                    GetUserBalance = Val(Mid(response, balanceStart, balanceEnd - balanceStart))
                    Debug.Print "无逗号格式解析，余额: " & GetUserBalance
                Else
                    GetUserBalance = -1
                    Debug.Print "无法解析余额，原始响应: " & response
                    Debug.Print "balanceStart: " & balanceStart & ", balanceEnd: " & balanceEnd
                End If
            End If
        End If
        
        If GetUserBalance >= 0 Then
            g_balance = GetUserBalance ' 更新全局余额
            Debug.Print "最终解析的余额: " & g_balance
        End If
    Else
        GetUserBalance = -1
        Debug.Print "API调用失败，原始响应: " & response
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "获取余额错误: " & Err.Description
    GetUserBalance = -1
End Function

' 充值（最终版）
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
        Debug.Print "充值成功"
    Else
        UserRecharge = APIError.ServerError
        Debug.Print "充值失败"
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

' 调试当前登录状态
Public Sub DebugLoginState()
    Debug.Print "=== 当前登录状态调试 ==="
    Debug.Print "用户名: " & g_username
    Debug.Print "用户ID: " & g_userId
    Debug.Print "用户余额: " & g_balance
    Debug.Print "Token长度: " & Len(g_userToken)
    Debug.Print "Token前30字符: " & Left(g_userToken, 30)
    Debug.Print "Token后30字符: " & Right(g_userToken, 30)
    Debug.Print "========================"
End Sub

' 测试HTTP请求头
Public Sub TestAuthorizationHeader()
    If Not IsUserLoggedIn() Then
        Debug.Print "用户未登录"
        Exit Sub
    End If
    
    Debug.Print "=== 测试Authorization头 ==="
    Debug.Print "完整的Authorization头: Bearer " & g_userToken
    Debug.Print "Token长度: " & Len(g_userToken)
    Debug.Print "========================"
    
    ' 手动测试余额查询
    Dim url As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=balance"
    response = SendHttpRequest(url, "GET")
    
    Debug.Print "手动余额查询响应: " & response
End Sub

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

' ==================== 用户友好界面函数 ====================

' 注册并登录新用户
Public Sub RegisterAndLogin()
    Dim username As String
    Dim password As String
    Dim confirmPassword As String
    Dim email As String
    Dim result As APIError
    
    ' 获取用户名
    username = InputBox("请输入用户名 (3-50个字符):", "注册")
    If username = "" Then Exit Sub
    
    ' 获取密码
    password = InputBox("请输入密码 (至少6个字符):", "注册")
    If password = "" Then Exit Sub
    
    ' 确认密码
    confirmPassword = InputBox("请再次输入密码:", "注册")
    If confirmPassword <> password Then
        MsgBox "两次输入的密码不一致", vbExclamation, "注册失败"
        Exit Sub
    End If
    
    ' 获取邮箱
    email = InputBox("请输入邮箱地址:", "注册")
    If email = "" Then Exit Sub
    
    ' 尝试注册
    Debug.Print "尝试注册用户: " & username
    result = UserRegister(username, password, email)
    
    Select Case result
        Case APIError.Success
            MsgBox "注册成功！正在自动登录...", vbInformation, "注册成功"
            
            ' 注册成功后自动登录
            UserLogin username, password
            
            If IsUserLoggedIn() Then
                MsgBox "登录成功！" & vbCrLf & GetCurrentUserInfo(), vbInformation, "登录成功"
            End If
            
        Case APIError.AuthError
            MsgBox "注册失败：用户名或邮箱已被使用", vbExclamation, "注册失败"
        Case APIError.ValidationError
            MsgBox "注册失败：输入数据不符合要求" & vbCrLf & _
                   "请检查：" & vbCrLf & _
                   "1. 用户名长度应为3-50个字符" & vbCrLf & _
                   "2. 密码长度应为6-100个字符" & vbCrLf & _
                   "3. 邮箱格式应正确", vbExclamation, "验证失败"
        Case APIError.RateLimitError
            MsgBox "请求过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "注册失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 登录现有用户
Public Sub LoginExistingUser()
    Dim username As String
    Dim password As String
    Dim result As APIError
    
    ' 获取用户名
    username = InputBox("请输入用户名:", "登录")
    If username = "" Then Exit Sub
    
    ' 获取密码
    password = InputBox("请输入密码:", "登录")
    If password = "" Then Exit Sub
    
    ' 尝试登录
    Debug.Print "尝试登录用户: " & username
    result = UserLogin(username, password)
    
    Select Case result
        Case APIError.Success
            MsgBox "登录成功！" & vbCrLf & GetCurrentUserInfo(), vbInformation, "登录成功"
        Case APIError.AuthError
            MsgBox "用户名或密码错误", vbExclamation, "登录失败"
        Case APIError.ValidationError
            MsgBox "登录失败：输入数据不符合要求" & vbCrLf & _
                   "请检查：" & vbCrLf & _
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

' 查看余额
Public Sub CheckBalance()
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

' 充值
Public Sub RechargeAccount()
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation, "未登录"
        Exit Sub
    End If
    
    Dim amountStr As String
    Dim amount As Double
    Dim paymentMethod As String
    Dim result As APIError
    
    ' 获取充值金额
    amountStr = InputBox("请输入充值金额:", "充值", "50")
    If amountStr = "" Then Exit Sub
    
    amount = Val(amountStr)
    If amount <= 0 Then
        MsgBox "充值金额必须大于0", vbExclamation, "无效金额"
        Exit Sub
    End If
    
    ' 选择支付方式
    paymentMethod = InputBox("请选择支付方式:" & vbCrLf & "1. 支付宝" & vbCrLf & "2. 微信支付" & vbCrLf & "3. 银行卡" & vbCrLf & vbCrLf & "请输入选项数字:", "选择支付方式", "1")
    
    Select Case paymentMethod
        Case "1"
            paymentMethod = "alipay"
        Case "2"
            paymentMethod = "wechat"
        Case "3"
            paymentMethod = "bankcard"
        Case Else
            MsgBox "无效的支付方式选择", vbExclamation, "支付方式错误"
            Exit Sub
    End Select
    
    ' 尝试充值
    Debug.Print "尝试充值: " & amount & "元，支付方式: " & paymentMethod
    result = UserRecharge(amount, paymentMethod)
    
    Select Case result
        Case APIError.Success
            MsgBox "充值成功！" & vbCrLf & "充值金额: " & Format(amount, "0.00") & " 元" & vbCrLf & "当前余额: " & Format(g_balance, "0.00") & " 元", vbInformation, "充值成功"
        Case APIError.ValidationError
            MsgBox "充值失败：输入数据不符合要求", vbExclamation, "验证失败"
        Case APIError.RateLimitError
            MsgBox "请求过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "充值失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 登出
Public Sub Logout()
    UserLogout
    MsgBox "已成功登出", vbInformation, "登出"
End Sub

' ==================== 测试函数 ====================

' 测试完整流程
Public Sub TestCompleteFlow()
    ' 1. 注册新用户
    Debug.Print "=== 测试注册和登录流程 ==="
    RegisterAndLogin
    
    ' 2. 如果登录成功，查看余额
    If IsUserLoggedIn() Then
        CheckBalance
        
        ' 3. 充值
        RechargeAccount
        
        ' 4. 再次查看余额
        CheckBalance
        
        ' 5. 登出
        Logout
    End If
End Sub

' 测试服务器连接
Public Sub TestServerConnection()
    Debug.Print "=== 测试服务器连接 ==="
    
    ' 测试配置端点
    Dim response As String
    response = SendHttpRequest("https://lvren.cc/api/config.php", "GET")
    
    If response <> "" Then
        MsgBox "服务器连接正常", vbInformation, "连接测试"
    Else
        MsgBox "服务器连接失败", vbExclamation, "连接测试"
    End If
End Sub

' ==================== 新增功能：密码管理和软件授权 ====================

' 修改密码
Public Function ChangePassword(oldPassword As String, newPassword As String) As APIError
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        Debug.Print "修改密码失败: 用户未登录"
        ChangePassword = APIError.AuthError
        Exit Function
    End If
    
    ' 输入验证
    If Trim(oldPassword) = "" Or Len(oldPassword) < 6 Then
        Debug.Print "旧密码验证失败: 长度少于6个字符"
        ChangePassword = APIError.ValidationError
        Exit Function
    End If
    
    If Trim(newPassword) = "" Or Len(newPassword) < 6 Or Len(newPassword) > 100 Then
        Debug.Print "新密码验证失败: 长度不符合要求"
        ChangePassword = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "auth.php?action=change-password"
    postData = "{""old_password"":""" & EscapeJson(oldPassword) & """,""new_password"":""" & EscapeJson(newPassword) & """}"
    
    Debug.Print "修改密码数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        ChangePassword = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "修改密码响应: " & response
    
    If InStr(response, """success"":true") > 0 Then
        ChangePassword = APIError.Success
        Debug.Print "密码修改成功"
    Else
        ChangePassword = APIError.AuthError
        Debug.Print "密码修改失败"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "修改密码错误: " & Err.Description
    ChangePassword = APIError.ServerError
End Function

' 忘记密码
Public Function ForgotPassword(email As String) As APIError
    On Error GoTo ErrorHandler
    
    ' 输入验证
    If Trim(email) = "" Or InStr(email, "@") = 0 Or InStr(email, ".") = 0 Then
        Debug.Print "邮箱验证失败"
        ForgotPassword = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "auth.php?action=forgot-password"
    postData = "{""email"":""" & EscapeJson(email) & """}"
    
    Debug.Print "忘记密码数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        ForgotPassword = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "忘记密码响应: " & response
    
    If InStr(response, """success"":true") > 0 Then
        ForgotPassword = APIError.Success
        Debug.Print "重置密码邮件发送成功"
    Else
        ForgotPassword = APIError.AuthError
        Debug.Print "重置密码邮件发送失败"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "忘记密码错误: " & Err.Description
    ForgotPassword = APIError.ServerError
End Function

' 重置密码（使用重置令牌）
Public Function ResetPassword(token As String, newPassword As String) As APIError
    On Error GoTo ErrorHandler
    
    ' 输入验证
    If Trim(token) = "" Or Len(token) < 10 Then
        Debug.Print "重置令牌验证失败"
        ResetPassword = APIError.ValidationError
        Exit Function
    End If
    
    If Trim(newPassword) = "" Or Len(newPassword) < 6 Or Len(newPassword) > 100 Then
        Debug.Print "新密码验证失败: 长度不符合要求"
        ResetPassword = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "auth.php?action=reset-password"
    postData = "{""token"":""" & EscapeJson(token) & """,""password"":""" & EscapeJson(newPassword) & """}"
    
    Debug.Print "重置密码数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        ResetPassword = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "重置密码响应: " & response
    
    If InStr(response, """success"":true") > 0 Then
        ResetPassword = APIError.Success
        Debug.Print "密码重置成功"
    Else
        ResetPassword = APIError.AuthError
        Debug.Print "密码重置失败"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "重置密码错误: " & Err.Description
    ResetPassword = APIError.ServerError
End Function

' ==================== 软件授权功能 ====================

' 检查软件授权
Public Function CheckLicense(softwareId As String) As APIError
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        Debug.Print "检查授权失败: 用户未登录"
        CheckLicense = APIError.AuthError
        Exit Function
    End If
    
    If Trim(softwareId) = "" Or Len(softwareId) > 100 Then
        Debug.Print "软件ID验证失败"
        CheckLicense = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim response As String
    
    url = API_BASE_URL & "license.php?action=check&software_id=" & EscapeJson(softwareId)
    response = SendHttpRequest(url, "GET")
    
    Debug.Print "检查授权响应: " & response
    
    If response = "" Then
        CheckLicense = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    If InStr(response, """success"":true") > 0 Then
        CheckLicense = APIError.Success
        Debug.Print "软件授权有效"
    Else
        CheckLicense = APIError.AuthError
        Debug.Print "软件授权无效或已过期"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "检查授权错误: " & Err.Description
    CheckLicense = APIError.ServerError
End Function

' 获取用户所有授权
Public Function GetUserLicenses() As String
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        Debug.Print "获取授权列表失败: 用户未登录"
        GetUserLicenses = ""
        Exit Function
    End If
    
    Dim url As String
    Dim response As String
    
    url = API_BASE_URL & "license.php?action=list"
    response = SendHttpRequest(url, "GET")
    
    Debug.Print "获取授权列表响应: " & response
    
    If response <> "" And InStr(response, """success"":true") > 0 Then
        GetUserLicenses = response
        Debug.Print "授权列表获取成功"
    Else
        GetUserLicenses = ""
        Debug.Print "授权列表获取失败"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "获取授权列表错误: " & Err.Description
    GetUserLicenses = ""
End Function

' 创建新授权
Public Function CreateLicense(softwareId As String, durationDays As Integer, Optional maxDevices As Integer = 1) As APIError
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        Debug.Print "创建授权失败: 用户未登录"
        CreateLicense = APIError.AuthError
        Exit Function
    End If
    
    ' 输入验证
    If Trim(softwareId) = "" Or Len(softwareId) > 100 Then
        Debug.Print "软件ID验证失败"
        CreateLicense = APIError.ValidationError
        Exit Function
    End If
    
    If durationDays <= 0 Or durationDays > 3650 Then ' 最大10年
        Debug.Print "授权时长验证失败"
        CreateLicense = APIError.ValidationError
        Exit Function
    End If
    
    If maxDevices <= 0 Or maxDevices > 100 Then
        Debug.Print "最大设备数验证失败"
        CreateLicense = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "license.php?action=create"
    postData = "{""software_id"":""" & EscapeJson(softwareId) & """,""duration_days"":" & durationDays & ",""max_devices"":" & maxDevices & "}"
    
    Debug.Print "创建授权数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        CreateLicense = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "创建授权响应: " & response
    
    If InStr(response, """success"":true") > 0 Then
        CreateLicense = APIError.Success
        Debug.Print "授权创建成功"
    Else
        CreateLicense = APIError.AuthError
        Debug.Print "授权创建失败"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "创建授权错误: " & Err.Description
    CreateLicense = APIError.ServerError
End Function

' 续期授权
Public Function RenewLicense(licenseId As Long, durationDays As Integer) As APIError
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        Debug.Print "续期授权失败: 用户未登录"
        RenewLicense = APIError.AuthError
        Exit Function
    End If
    
    ' 输入验证
    If licenseId <= 0 Then
        Debug.Print "授权ID验证失败"
        RenewLicense = APIError.ValidationError
        Exit Function
    End If
    
    If durationDays <= 0 Or durationDays > 3650 Then ' 最大10年
        Debug.Print "续期时长验证失败"
        RenewLicense = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "license.php?action=renew"
    postData = "{""license_id"":" & licenseId & ",""duration_days"":" & durationDays & "}"
    
    Debug.Print "续期授权数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        RenewLicense = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "续期授权响应: " & response
    
    If InStr(response, """success"":true") > 0 Then
        RenewLicense = APIError.Success
        Debug.Print "授权续期成功"
    Else
        RenewLicense = APIError.AuthError
        Debug.Print "授权续期失败"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "续期授权错误: " & Err.Description
    RenewLicense = APIError.ServerError
End Function

' 禁用授权
Public Function DisableLicense(licenseId As Long) As APIError
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        Debug.Print "禁用授权失败: 用户未登录"
        DisableLicense = APIError.AuthError
        Exit Function
    End If
    
    ' 输入验证
    If licenseId <= 0 Then
        Debug.Print "授权ID验证失败"
        DisableLicense = APIError.ValidationError
        Exit Function
    End If
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "license.php?action=disable"
    postData = "{""license_id"":" & licenseId & "}"
    
    Debug.Print "禁用授权数据: " & postData
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        DisableLicense = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
    Debug.Print "禁用授权响应: " & response
    
    If InStr(response, """success"":true") > 0 Then
        DisableLicense = APIError.Success
        Debug.Print "授权禁用成功"
    Else
        DisableLicense = APIError.AuthError
        Debug.Print "授权禁用失败"
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "禁用授权错误: " & Err.Description
    DisableLicense = APIError.ServerError
End Function

' ==================== 新增功能的用户界面函数 ====================

' 修改密码界面
Public Sub ChangePasswordUI()
    Dim oldPassword As String
    Dim newPassword As String
    Dim confirmPassword As String
    Dim result As APIError
    
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation, "未登录"
        Exit Sub
    End If
    
    ' 获取旧密码
    oldPassword = InputBox("请输入当前密码:", "修改密码")
    If Trim(oldPassword) = "" Then
        Exit Sub
    End If
    
    ' 获取新密码
    newPassword = InputBox("请输入新密码 (至少6个字符):", "修改密码")
    If Trim(newPassword) = "" Then
        Exit Sub
    End If
    
    If Len(newPassword) < 6 Then
        MsgBox "新密码长度至少6个字符", vbExclamation, "密码长度不足"
        Exit Sub
    End If
    
    ' 确认新密码
    confirmPassword = InputBox("请再次输入新密码:", "确认密码")
    If newPassword <> confirmPassword Then
        MsgBox "两次输入的密码不一致", vbExclamation, "密码不匹配"
        Exit Sub
    End If
    
    ' 执行修改密码
    result = ChangePassword(oldPassword, newPassword)
    
    Select Case result
        Case APIError.Success
            MsgBox "密码修改成功！", vbInformation, "修改成功"
        Case APIError.ValidationError
            MsgBox "旧密码不正确或新密码格式不正确", vbExclamation, "验证失败"
        Case APIError.AuthError
            MsgBox "旧密码不正确", vbExclamation, "认证失败"
        Case APIError.RateLimitError
            MsgBox "请求过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "密码修改失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 忘记密码界面
Public Sub ForgotPasswordUI()
    Dim email As String
    Dim result As APIError
    
    ' 获取邮箱
    email = InputBox("请输入您的注册邮箱:", "忘记密码")
    If Trim(email) = "" Then
        Exit Sub
    End If
    
    If InStr(email, "@") = 0 Or InStr(email, ".") = 0 Then
        MsgBox "邮箱格式不正确", vbExclamation, "邮箱错误"
        Exit Sub
    End If
    
    ' 执行忘记密码
    result = ForgotPassword(email)
    
    Select Case result
        Case APIError.Success
            MsgBox "重置密码链接已发送到您的邮箱，请查收邮件", vbInformation, "发送成功"
        Case APIError.ValidationError
            MsgBox "邮箱格式不正确", vbExclamation, "邮箱错误"
        Case APIError.RateLimitError
            MsgBox "请求过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "发送失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 检查软件授权界面
Public Sub CheckLicenseUI()
    Dim softwareId As String
    Dim result As APIError
    
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation, "未登录"
        Exit Sub
    End If
    
    ' 获取软件ID
    softwareId = InputBox("请输入软件ID:", "检查授权")
    If Trim(softwareId) = "" Then
        Exit Sub
    End If
    
    ' 执行检查授权
    result = CheckLicense(softwareId)
    
    Select Case result
        Case APIError.Success
            MsgBox "软件授权有效", vbInformation, "授权有效"
        Case APIError.ValidationError
            MsgBox "软件ID格式不正确", vbExclamation, "输入错误"
        Case APIError.AuthError
            MsgBox "软件授权无效或已过期", vbExclamation, "授权无效"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "检查失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 查看所有授权界面
Public Sub ViewLicensesUI()
    Dim response As String
    
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation, "未登录"
        Exit Sub
    End If
    
    ' 获取授权列表
    response = GetUserLicenses()
    
    If response <> "" Then
        ' 这里可以解析JSON并显示更详细的信息
        ' 为了简化，我们显示原始响应
        MsgBox "您的授权列表:" & vbCrLf & response, vbInformation, "授权列表"
    Else
        MsgBox "获取授权列表失败", vbExclamation, "获取失败"
    End If
End Sub

' 测试余额获取功能
Public Sub TestBalanceParsing()
    Debug.Print "=== 测试余额解析功能 ==="
    
    ' 模拟两种可能的响应格式
    Dim normalJson As String
    Dim brokenJson As String
    
    ' 正常格式
    normalJson = "{""success"":true,""balance"":150.75,""message"":""余额查询成功""}"
    
    ' 缺少逗号的格式（当前服务器返回的格式）
    brokenJson = "{""success"":true""balance"":150.75""message"":""余额查询成功""}"
    
    Debug.Print "正常JSON: " & normalJson
    Debug.Print "异常JSON: " & brokenJson
    
    ' 测试解析函数
    Dim result1 As Double, result2 As Double
    result1 = ParseBalanceFromJson(normalJson)
    result2 = ParseBalanceFromJson(brokenJson)
    
    Debug.Print "正常JSON解析结果: " & result1
    Debug.Print "异常JSON解析结果: " & result2
End Sub

' 从JSON字符串中解析余额的辅助函数
Private Function ParseBalanceFromJson(jsonString As String) As Double
    Dim balanceStart As Integer
    Dim balanceEnd As Integer
    balanceStart = InStr(jsonString, """balance"":") + 10
    
    ' 尝试找到结束位置 - 可能是逗号或引号
    balanceEnd = InStr(balanceStart, jsonString, ",")
    If balanceEnd = 0 Then
        ' 如果没有逗号，尝试找下一个引号
        balanceEnd = InStr(balanceStart, jsonString, """")
    End If
    
    If balanceEnd > balanceStart Then
        ParseBalanceFromJson = Val(Mid(jsonString, balanceStart, balanceEnd - balanceStart))
    Else
        ParseBalanceFromJson = -1
    End If
End Function

' 测试登录数据解析
Public Sub TestLoginParsing()
    Debug.Print "=== 测试登录数据解析 ==="
    
    ' 模拟登录响应
    Dim loginResponse As String
    loginResponse = "{""success"":true,""message"":""登录成功"",""token"":""test_token"",""user"":{""id"":""16"",""username"":""wy123456"",""balance"":""900.00""}}"
    
    Debug.Print "登录响应: " & loginResponse
    
    ' 测试ID提取
    Dim idStart As Integer, idEnd As Integer
    idStart = InStr(loginResponse, """user"":{") + 7
    idStart = InStr(idStart, loginResponse, """id"":") + 5
    idEnd = InStr(idStart, loginResponse, ",")
    
    If idEnd > idStart Then
        Dim userId As Long
        userId = Val(Mid(loginResponse, idStart, idEnd - idStart))
        Debug.Print "提取的用户ID: " & userId
    End If
    
    ' 测试余额提取
    Dim balanceStart As Integer, balanceEnd As Integer
    balanceStart = InStr(loginResponse, """user"":{") + 7
    balanceStart = InStr(balanceStart, loginResponse, """balance"":") + 10
    balanceEnd = InStr(balanceStart, loginResponse, ",")
    
    If balanceEnd > balanceStart Then
        Dim balance As Double
        balance = Val(Mid(loginResponse, balanceStart, balanceEnd - balanceStart))
        Debug.Print "提取的用户余额: " & balance
    End If
End Sub

' Base64 URL解码函数（用于JWT）
Private Function Base64UrlDecode(base64Url As String) As String
    On Error Resume Next
    Dim base64 As String
    base64 = Replace(base64Url, "-", "+")
    base64 = Replace(base64, "_", "/")
    
    ' 补齐padding
    Dim mod4 As Integer
    mod4 = Len(base64) Mod 4
    If mod4 > 0 Then
        base64 = base64 & String(4 - mod4, "=")
    End If
    
    Base64UrlDecode = Base64Decode(base64)
End Function

' 基础Base64解码函数（VBA原生支持）
Private Function Base64Decode(base64 As String) As String
    On Error Resume Next
    Dim xml As Object
    Set xml = CreateObject("MSXML2.DOMDocument")
    
    Dim node As Object
    Set node = xml.createElement("base64")
    node.DataType = "bin.base64"
    node.Text = base64
    
    Base64Decode = StrConv(node.nodeTypedValue, vbUnicode)
End Function

' 增强的余额查询调试函数
Public Sub DebugBalanceQuery()
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation, "错误"
        Exit Sub
    End If
    
    Debug.Print "=== 增强余额查询调试 ==="
    Debug.Print "当前用户: " & g_username & " (ID: " & g_userId & ")"
    Debug.Print "全局余额: " & g_balance
    
    ' 分析Token内容
    If g_userToken <> "" Then
        Debug.Print "Token分析:"
        Debug.Print "  Token长度: " & Len(g_userToken)
        
        Dim parts() As String
        parts = Split(g_userToken, ".")
        
        If UBound(parts) >= 1 Then
            Dim payload As String
            payload = Base64UrlDecode(parts(1))
            Debug.Print "  Token payload: " & payload
            
            ' 尝试从payload提取user_id
            Dim userIdPos As Integer
            userIdPos = InStr(payload, "user_id")
            If userIdPos > 0 Then
                Dim userIdStart As Integer
                userIdStart = InStr(userIdPos, payload, ":") + 1
                Dim userIdEnd As Integer
                userIdEnd = InStr(userIdStart, payload, ",")
                If userIdEnd = 0 Then userIdEnd = InStr(userIdStart, payload, "}")
                
                If userIdEnd > userIdStart Then
                    Dim tokenUserId As String
                    tokenUserId = Mid(payload, userIdStart, userIdEnd - userIdStart)
                    Debug.Print "  Token中的user_id: " & tokenUserId
                End If
            End If
        End If
    End If
    
    ' 执行余额查询
    Dim url As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=balance"
    response = SendHttpRequest(url, "GET")
    
    Debug.Print "余额查询响应: " & response
    Debug.Print "响应分析:"
    Debug.Print "  响应长度: " & Len(response)
    Debug.Print "  包含success:true: " & (InStr(response, """success"":true") > 0)
    Debug.Print "  包含balance: " & (InStr(response, """balance""") > 0)
    
    ' 解析余额
    If InStr(response, """success"":true") > 0 Then
        Dim balanceStart As Integer, balanceEnd As Integer
        balanceStart = InStr(response, """balance"":") + 10
        
        ' 查找下一个字符
        Dim nextChar As String
        nextChar = Mid(response, balanceStart, 1)
        Debug.Print "  balance后的第一个字符: '" & nextChar & "'"
        
        ' 尝试不同的结束位置
        balanceEnd = InStr(balanceStart, response, ",")
        If balanceEnd > 0 Then
            Dim extractedValue As String
            extractedValue = Mid(response, balanceStart, balanceEnd - balanceStart)
            Debug.Print "  逗号前提取: '" & extractedValue & "' -> " & Val(extractedValue)
        Else
            balanceEnd = InStr(balanceStart, response, """")
            If balanceEnd > 0 Then
                extractedValue = Mid(response, balanceStart, balanceEnd - balanceStart)
                Debug.Print "  引号前提取: '" & extractedValue & "' -> " & Val(extractedValue)
            End If
        End If
    End If
    
    Debug.Print "=== 调试结束 ==="
End Sub