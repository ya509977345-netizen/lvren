' Access VBA API快速入门示例
' 最简化的API使用示例，适合快速上手

Option Explicit

' 基础设置
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

' ==================== 核心API函数 ====================

' 发送HTTP请求
Private Function SendHttpRequest(url As String, method As String, Optional data As String = "") As String
    On Error GoTo ErrorHandler
    
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP")
    
    http.Open method, url, False
    http.setRequestHeader "Content-Type", "application/json"
    If g_userToken <> "" Then
        http.setRequestHeader "Authorization", "Bearer " & g_userToken
    End If
    http.setRequestHeader "X-API-Key", API_KEY
    
    If method = "POST" Then
        http.send data
    Else
        http.send
    End If
    
    If http.Status = 200 Then
        SendHttpRequest = http.responseText
    ElseIf http.Status = 429 Then
        Err.Raise 1006, "SendHttpRequest", "请求过于频繁"
    Else
        Err.Raise 1000, "SendHttpRequest", "HTTP错误: " & http.Status
    End If
    
    Exit Function
    
ErrorHandler:
    SendHttpRequest = ""
End Function

' ==================== 用户认证函数 ====================

' 用户登录
Public Function UserLogin(username As String, password As String) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "auth.php?action=login"
    postData = "{""username"":""" & username & """,""password"":""" & password & """}"
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        UserLogin = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
        Exit Function
    End If
    
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
End Function

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
End Function

' 充值
Public Function UserRecharge(amount As Double, paymentMethod As String) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=recharge"
    postData = "{""amount"":" & amount & ",""payment_method"":""" & paymentMethod & """}"
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        UserRecharge = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
    ElseIf InStr(response, """success"":true") > 0 Then
        g_balance = g_balance + amount
        UserRecharge = APIError.Success
    Else
        UserRecharge = APIError.ServerError
    End If
    
    Exit Function
    
ErrorHandler:
    UserRecharge = APIError.ServerError
End Function

' 扣费
Public Function DeductBalance(amount As Double, description As String) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    url = API_BASE_URL & "wallet.php?action=deduct"
    postData = "{""amount"":" & amount & ",""description"":""" & description & """}"
    
    response = SendHttpRequest(url, "POST", postData)
    
    If response = "" Then
        DeductBalance = IIf(Err.Number = 1006, APIError.RateLimitError, APIError.NetworkError)
    ElseIf InStr(response, """success"":true") > 0 Then
        g_balance = g_balance - amount
        DeductBalance = APIError.Success
    Else
        If InStr(response, "余额不足") > 0 Then
            DeductBalance = APIError.AuthError
        Else
            DeductBalance = APIError.ServerError
        End If
    End If
    
    Exit Function
    
ErrorHandler:
    DeductBalance = APIError.ServerError
End Function

' ==================== 辅助函数 ====================

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

' 获取当前用户信息
Public Function GetCurrentUserInfo() As String
    If IsUserLoggedIn() Then
        GetCurrentUserInfo = "用户: " & g_username & " (ID: " & g_userId & "), 余额: " & Format(g_balance, "0.00") & " 元"
    Else
        GetCurrentUserInfo = "未登录"
    End If
End Function

' ==================== 简单使用示例 ====================

' 示例1：简单登录
Public Sub QuickLogin()
    Dim username As String
    Dim password As String
    Dim result As APIError
    
    username = InputBox("请输入用户名:", "登录")
    If username = "" Then Exit Sub
    
    password = InputBox("请输入密码:", "登录")
    If password = "" Then Exit Sub
    
    result = UserLogin(username, password)
    
    Select Case result
        Case APIError.Success
            MsgBox "登录成功！" & vbCrLf & GetCurrentUserInfo(), vbInformation, "成功"
        Case APIError.AuthError
            MsgBox "用户名或密码错误", vbExclamation, "登录失败"
        Case APIError.RateLimitError
            MsgBox "请求过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "登录失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 示例2：查看余额
Public Sub QuickCheckBalance()
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

' 示例3：简单充值
Public Sub QuickRecharge()
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation, "未登录"
        Exit Sub
    End If
    
    Dim amount As String
    Dim rechargeAmount As Double
    Dim result As APIError
    
    amount = InputBox("请输入充值金额:", "充值", "50")
    If amount = "" Then Exit Sub
    
    rechargeAmount = Val(amount)
    
    If rechargeAmount <= 0 Then
        MsgBox "充值金额必须大于0", vbExclamation, "无效金额"
        Exit Sub
    End If
    
    result = UserRecharge(rechargeAmount, "alipay")
    
    Select Case result
        Case APIError.Success
            MsgBox "充值成功！" & vbCrLf & "充值金额: " & Format(rechargeAmount, "0.00") & " 元" & vbCrLf & _
                   "当前余额: " & Format(g_balance, "0.00") & " 元", vbInformation, "充值成功"
        Case APIError.RateLimitError
            MsgBox "操作过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "充值失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 示例4：使用功能并扣费
Public Sub QuickUseFeature()
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录", vbExclamation, "未登录"
        Exit Sub
    End If
    
    Const featureCost As Double = 5.0
    Dim result As APIError
    
    result = DeductBalance(featureCost, "使用高级功能")
    
    Select Case result
        Case APIError.Success
            MsgBox "功能使用成功！" & vbCrLf & "扣除费用: " & Format(featureCost, "0.00") & " 元" & vbCrLf & _
                   "当前余额: " & Format(g_balance, "0.00") & " 元", vbInformation, "使用成功"
            
            ' 这里可以添加实际功能的代码
            ' Call ExecuteAdvancedFunction()
            
        Case APIError.AuthError
            MsgBox "余额不足，当前余额: " & Format(g_balance, "0.00") & " 元", vbExclamation, "余额不足"
        Case APIError.RateLimitError
            MsgBox "操作过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误", vbExclamation, "网络错误"
        Case Else
            MsgBox "功能使用失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub

' 示例5：完整的使用流程
Public Sub CompleteWorkflow()
    ' 1. 登录
    Dim username As String
    Dim password As String
    Dim result As APIError
    
    username = InputBox("请输入用户名:", "登录")
    If username = "" Then Exit Sub
    
    password = InputBox("请输入密码:", "登录")
    If password = "" Then Exit Sub
    
    result = UserLogin(username, password)
    
    If result <> APIError.Success Then
        MsgBox "登录失败", vbExclamation, "错误"
        Exit Sub
    End If
    
    MsgBox "登录成功！欢迎使用本系统", vbInformation, "欢迎"
    
    ' 2. 显示用户信息
    MsgBox GetCurrentUserInfo(), vbInformation, "用户信息"
    
    ' 3. 充值（可选）
    Dim rechargeChoice As VbMsgBoxResult
    rechargeChoice = MsgBox("是否要充值？", vbQuestion + vbYesNo, "充值")
    
    If rechargeChoice = vbYes Then
        Call QuickRecharge
    End If
    
    ' 4. 使用功能
    Dim featureChoice As VbMsgBoxResult
    featureChoice = MsgBox("是否要使用高级功能（费用5元）？", vbQuestion + vbYesNo, "使用功能")
    
    If featureChoice = vbYes Then
        Call QuickUseFeature
    End If
    
    ' 5. 显示最终信息
    MsgBox "感谢使用，再见！" & vbCrLf & GetCurrentUserInfo(), vbInformation, "结束"
    
    ' 6. 登出
    UserLogout
End Sub

' ==================== 窗体按钮事件示例 ====================

' 将这些代码复制到Access窗体的相应按钮事件中

' 登录按钮
Private Sub btnLogin_Click()
    Call QuickLogin
End Sub

' 查看余额按钮
Private Sub btnCheckBalance_Click()
    Call QuickCheckBalance
End Sub

' 充值按钮
Private Sub btnRecharge_Click()
    Call QuickRecharge
End Sub

' 使用功能按钮
Private Sub btnUseFeature_Click()
    Call QuickUseFeature
End Sub

' 登出按钮
Private Sub btnLogout_Click()
    UserLogout
    MsgBox "已成功登出", vbInformation, "登出"
End Sub

' 显示用户信息按钮
Private Sub btnShowUserInfo_Click()
    MsgBox GetCurrentUserInfo(), vbInformation, "用户信息"
End Sub