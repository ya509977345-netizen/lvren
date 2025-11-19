' VBA API调用模块 - 用于Access VBA调用服务器API
' 需要在VBA项目中添加引用：Microsoft XML, v6.0

Option Explicit

' API服务器地址 - 请替换为你的实际服务器地址
Private Const API_BASE_URL As String = "http://your-server.com/api/"
Private Const API_KEY As String = "your_api_secret_key"

' 全局变量存储用户登录信息
Private g_userToken As String
Private g_userId As Long
Private g_username As String
Private g_balance As Double

' 错误处理枚举
Public Enum APIError
    Success = 0
    NetworkError = 1
    AuthError = 2
    ServerError = 3
    InvalidResponse = 4
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

' 发送HTTP请求
Private Function SendHttpRequest(url As String, method As String, Optional data As String = "", Optional contentType As String = "application/json") As String
    On Error GoTo ErrorHandler
    
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP")
    
    ' 创建HTTP请求
    http.Open method, url, False
    
    ' 设置请求头
    http.setRequestHeader "Content-Type", contentType
    http.setRequestHeader "Authorization", "Bearer " & g_userToken
    http.setRequestHeader "X-API-Key", API_KEY
    
    ' 发送请求
    If method = "POST" Then
        http.send data
    Else
        http.send
    End If
    
    ' 检查响应状态
    If http.Status = 200 Then
        SendHttpRequest = http.responseText
    Else
        ' 处理错误状态
        Select Case http.Status
            Case 400
                Err.Raise 1001, "SendHttpRequest", "请求参数错误"
            Case 401
                Err.Raise 1002, "SendHttpRequest", "认证失败"
            Case 403
                Err.Raise 1003, "SendHttpRequest", "权限不足"
            Case 404
                Err.Raise 1004, "SendHttpRequest", "接口不存在"
            Case 500
                Err.Raise 1005, "SendHttpRequest", "服务器内部错误"
            Case Else
                Err.Raise 1000, "SendHttpRequest", "HTTP错误: " & http.Status
        End Select
    End If
    
    Exit Function
    
ErrorHandler:
    SendHttpRequest = ""
    Debug.Print "HTTP请求错误: " & Err.Description
End Function

' 解析JSON响应
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

' 用户登录
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
    Else
        UserLogin = APIError.AuthError
    End If
    
    Exit Function
    
ErrorHandler:
    UserLogin = APIError.ServerError
    Debug.Print "登录错误: " & Err.Description
End Function

' 用户注册
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
    Else
        UserRegister = APIError.ServerError
    End If
    
    Exit Function
    
ErrorHandler:
    UserRegister = APIError.ServerError
    Debug.Print "注册错误: " & Err.Description
End Function

' 验证Token
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
    Else
        VerifyToken = APIError.AuthError
    End If
    
    Exit Function
    
ErrorHandler:
    VerifyToken = APIError.ServerError
    Debug.Print "Token验证错误: " & Err.Description
End Function

' ==================== 钱包API ====================

' 获取用户余额
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

' 用户充值
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
    Else
        UserRecharge = APIError.ServerError
    End If
    
    Exit Function
    
ErrorHandler:
    UserRecharge = APIError.ServerError
    Debug.Print "充值错误: " & Err.Description
End Function

' 扣费操作
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
    Else
        DeductBalance = APIError.ServerError
    End If
    
    Exit Function
    
ErrorHandler:
    DeductBalance = APIError.ServerError
    Debug.Print "扣费错误: " & Err.Description
End Function

' ==================== 授权管理API ====================

' 检查软件授权
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

' 创建新授权
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
    Else
        CreateLicense = APIError.ServerError
    End If
    
    Exit Function
    
ErrorHandler:
    CreateLicense = APIError.ServerError
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

' 示例：完整的登录和授权检查流程
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

' 示例：软件功能使用前的授权检查
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
    If DeductBalance(featureCost, "使用软件功能") = APIError.Success Then
        CheckSoftwareAccess = True
        MsgBox "功能使用成功，已扣除费用：" & Format(featureCost, "0.00") & "元", vbInformation
    Else
        CheckSoftwareAccess = False
        MsgBox "功能使用失败，请重试", vbExclamation
    End If
End Function