' VBA API连接问题诊断和修复模块
' 用于帮助诊断和解决API连接问题

Option Explicit

' 诊断连接问题的详细测试函数
Public Function DiagnoseConnection() As String
    Dim result As String
    result = "=== API连接诊断 ===" & vbCrLf & vbCrLf
    
    ' 1. 检查基础网络连接
    result = result & "1. 检查基础网络连接..." & vbCrLf
    
    On Error Resume Next
    Dim http As Object
    Set http = CreateObject("MSXML2.XMLHTTP")
    
    If Err.Number <> 0 Then
        result = result & "   ❌ 无法创建MSXML2.XMLHTTP对象" & vbCrLf
        result = result & "   可能原因: 未安装Microsoft XML Core Services" & vbCrLf
        result = result & "   解决方案: 安装MSXML或尝试使用MSXML2.ServerXMLHTTP" & vbCrLf & vbCrLf
        DiagnoseConnection = result
        Exit Function
    End If
    
    result = result & "   ✅ MSXML2.XMLHTTP对象创建成功" & vbCrLf & vbCrLf
    
    ' 2. 测试基础HTTP连接
    result = result & "2. 测试基础HTTP连接..." & vbCrLf
    
    On Error Resume Next
    http.Open "GET", "https://lvren.cc", False
    http.send
    
    If Err.Number <> 0 Then
        result = result & "   ❌ 基础HTTP连接失败" & vbCrLf
        result = result & "   错误: " & Err.Description & vbCrLf
        result = result & "   可能原因:" & vbCrLf
        result = result & "   - 网络连接问题" & vbCrLf
        result = result & "   - 防火墙阻止连接" & vbCrLf
        result = result & "   - 代理设置问题" & vbCrLf
        result = result & "   - SSL/TLS证书问题" & vbCrLf & vbCrLf
        
        ' 尝试HTTP而非HTTPS
        http.Open "GET", "http://lvren.cc", False
        http.send
        If Err.Number = 0 And http.Status = 200 Then
            result = result & "   💡 HTTP连接成功，但HTTPS失败" & vbCrLf
            result = result & "   可能是SSL/TLS配置问题" & vbCrLf
        End If
        
        DiagnoseConnection = result
        Exit Function
    End If
    
    result = result & "   ✅ 基础HTTP连接成功" & vbCrLf
    result = result & "   状态码: " & http.Status & vbCrLf & vbCrLf
    
    ' 3. 测试API基础URL
    result = result & "3. 测试API基础URL..." & vbCrLf
    
    On Error Resume Next
    http.Open "GET", "https://lvren.cc/api", False
    http.send
    
    If Err.Number <> 0 Then
        result = result & "   ❌ API基础URL连接失败" & vbCrLf
        result = result & "   错误: " & Err.Description & vbCrLf & vbCrLf
    Else
        result = result & "   ✅ API基础URL连接成功" & vbCrLf
        result = result & "   状态码: " & http.Status & vbCrLf & vbCrLf
    End If
    
    ' 4. 测试API配置端点
    result = result & "4. 测试API配置端点..." & vbCrLf
    
    On Error Resume Next
    http.Open "GET", "https://lvren.cc/api/config.php", False
    http.send
    
    If Err.Number <> 0 Then
        result = result & "   ❌ API配置端点连接失败" & vbCrLf
        result = result & "   错误: " & Err.Description & vbCrLf & vbCrLf
    ElseIf http.Status <> 200 Then
        result = result & "   ❌ API配置端点返回错误状态" & vbCrLf
        result = result & "   状态码: " & http.Status & vbCrLf
        result = result & "   响应: " & Left(http.responseText, 200) & "..." & vbCrLf & vbCrLf
    Else
        result = result & "   ✅ API配置端点连接成功" & vbCrLf
        result = result & "   状态码: " & http.Status & vbCrLf
        result = result & "   响应长度: " & Len(http.responseText) & " 字符" & vbCrLf & vbCrLf
    End If
    
    ' 5. 测试API登录端点
    result = result & "5. 测试API登录端点..." & vbCrLf
    
    On Error Resume Next
    http.Open "POST", "https://lvren.cc/api/auth.php?action=login", False
    http.setRequestHeader "Content-Type", "application/json"
    http.setRequestHeader "X-API-Key", "Wang869678"
    http.send "{""username"":""test"",""password"":""test""}"
    
    If Err.Number <> 0 Then
        result = result & "   ❌ API登录端点连接失败" & vbCrLf
        result = result & "   错误: " & Err.Description & vbCrLf & vbCrLf
    Else
        result = result & "   ✅ API登录端点连接成功" & vbCrLf
        result = result & "   状态码: " & http.Status & vbCrLf
        result = result & "   响应: " & Left(http.responseText, 200) & "..." & vbCrLf & vbCrLf
    End If
    
    ' 6. 检查VBA环境
    result = result & "6. 检查VBA环境..." & vbCrLf
    
    On Error Resume Next
    Dim vbaVersion As String
    vbaVersion = Application.Version
    
    If Err.Number = 0 Then
        result = result & "   ✅ Access版本: " & vbaVersion & vbCrLf
    Else
        result = result & "   ⚠️ 无法获取Access版本" & vbCrLf
    End If
    
    On Error Resume Next
    Dim xmlVersion As String
    Set http = CreateObject("MSXML2.XMLHTTP.6.0")
    If Err.Number = 0 Then
        result = result & "   ✅ MSXML版本: 6.0" & vbCrLf
    Else
        Set http = CreateObject("MSXML2.XMLHTTP.3.0")
        If Err.Number = 0 Then
            result = result & "   ⚠️ MSXML版本: 3.0 (建议升级到6.0)" & vbCrLf
        Else
            result = result & "   ❌ MSXML未正确安装" & vbCrLf
        End If
    End If
    
    DiagnoseConnection = result
End Function

' 显示诊断结果
Public Sub ShowConnectionDiagnosis()
    Dim diagnosis As String
    diagnosis = DiagnoseConnection()
    
    ' 创建诊断结果窗体或显示在消息框中
    ' 由于诊断结果可能很长，使用Debug.Print和文件记录
    
    Debug.Print diagnosis
    
    ' 尝试将诊断结果写入临时文件
    Dim fso As Object
    Dim file As Object
    Dim tempPath As String
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    tempPath = fso.GetSpecialFolder(2) & "\api_diagnosis.txt" ' 2 = Temporary Folder
    
    Set file = fso.CreateTextFile(tempPath, True)
    file.Write diagnosis
    file.Close
    
    MsgBox "API连接诊断完成！" & vbCrLf & vbCrLf & _
           "诊断结果已打印到立即窗口，并保存到:" & vbCrLf & _
           tempPath & vbCrLf & vbCrLf & _
           "请查看诊断结果以确定连接问题的原因。", vbInformation, "诊断完成"
    
    ' 尝试打开诊断文件
    On Error Resume Next
    FollowHyperlink tempPath
End Sub

' 增强版HTTP请求函数，包含更多错误信息和兼容性处理
Public Function SendHttpRequestEnhanced(url As String, method As String, Optional data As String = "", Optional useSSL As Boolean = True) As String
    On Error GoTo ErrorHandler
    
    Dim http As Object
    Dim attempt As Integer
    Dim maxAttempts As Integer
    maxAttempts = 3
    
    ' 尝试不同版本的XMLHTTP对象
    For attempt = 1 To maxAttempts
        Select Case attempt
            Case 1
                Set http = CreateObject("MSXML2.XMLHTTP.6.0")
            Case 2
                Set http = CreateObject("MSXML2.XMLHTTP.3.0")
            Case 3
                Set http = CreateObject("MSXML2.XMLHTTP")
        End Select
        
        If Not http Is Nothing Then
            Exit For
        End If
    Next attempt
    
    If http Is Nothing Then
        Debug.Print "无法创建XMLHTTP对象"
        SendHttpRequestEnhanced = ""
        Exit Function
    End If
    
    ' 设置超时时间（毫秒）
    If attempt = 1 Then ' 只有6.0版本支持超时设置
        On Error Resume Next
        http.setTimeouts 10000, 10000, 15000, 10000 ' 连接、发送、接收、总超时
        On Error GoTo ErrorHandler
    End If
    
    ' 对于SSL问题，尝试不同的设置
    If useSSL And Left(url, 5) = "https" Then
        On Error Resume Next
        ' 尝试设置SSL选项（仅适用于某些版本）
        http.setOption 2, 13056 ' SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS
        On Error GoTo ErrorHandler
    End If
    
    http.Open method, url, False
    http.setRequestHeader "Content-Type", "application/json"
    http.setRequestHeader "X-API-Key", "Wang869678"
    
    If method = "POST" Then
        http.send data
    Else
        http.send
    End If
    
    Debug.Print "请求URL: " & url
    Debug.Print "请求方法: " & method
    Debug.Print "响应状态: " & http.Status
    Debug.Print "响应头: " & http.getAllResponseHeaders
    Debug.Print "响应内容: " & Left(http.responseText, 200) & "..."
    
    If http.Status = 200 Then
        SendHttpRequestEnhanced = http.responseText
    Else
        Debug.Print "HTTP错误: " & http.Status & " - " & http.statusText
        SendHttpRequestEnhanced = ""
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "HTTP请求错误: " & Err.Description & " (错误号: " & Err.Number & ")"
    Debug.Print "尝试次数: " & attempt
    Debug.Print "请求URL: " & url
    
    ' 如果是SSL证书错误，尝试不使用SSL
    If Err.Number = -2147483638 And useSSL Then ' SSL证书错误
        Debug.Print "检测到SSL证书错误，尝试HTTP连接..."
        If Left(url, 5) = "https" Then
            Dim httpUrl As String
            httpUrl = "http" & Mid(url, 6)
            SendHttpRequestEnhanced = SendHttpRequestEnhanced(httpUrl, method, data, False)
            Exit Function
        End If
    End If
    
    SendHttpRequestEnhanced = ""
End Function

' 测试增强版请求函数
Public Sub TestEnhancedConnection()
    Dim response As String
    
    Debug.Print "=== 测试增强版连接 ==="
    
    ' 测试1: 基础连接
    Debug.Print "测试1: 基础连接"
    response = SendHttpRequestEnhanced("https://lvren.cc/api/config.php", "GET")
    
    If response <> "" Then
        Debug.Print "✅ 基础连接成功"
    Else
        Debug.Print "❌ 基础连接失败"
    End If
    
    ' 测试2: 登录请求
    Debug.Print vbCrLf & "测试2: 登录请求"
    response = SendHttpRequestEnhanced("https://lvren.cc/api/auth.php?action=login", "POST", "{""username"":""test"",""password"":""test""}")
    
    If response <> "" Then
        Debug.Print "✅ 登录请求成功"
        Debug.Print "响应: " & response
    Else
        Debug.Print "❌ 登录请求失败"
    End If
End Sub

' 常见问题解决方案
Public Sub ShowTroubleshootingTips()
    Dim tips As String
    
    tips = "=== 常见连接问题解决方案 ===" & vbCrLf & vbCrLf
    tips = tips & "1. 网络连接问题:" & vbCrLf
    tips = tips & "   - 检查网络连接是否正常" & vbCrLf
    tips = tips & "   - 尝试访问 https://lvren.cc 确认网站可访问" & vbCrLf
    tips = tips & "   - 检查防火墙设置是否阻止了Access" & vbCrLf & vbCrLf
    
    tips = tips & "2. SSL/TLS证书问题:" & vbCrLf
    tips = tips & "   - 更新Windows根证书" & vbCrLf
    tips = tips & "   - 更新Internet Explorer浏览器(使用与Access相同的SSL设置)" & vbCrLf
    tips = tips & "   - 尝试使用HTTP而非HTTPS" & vbCrLf & vbCrLf
    
    tips = tips & "3. MSXML库问题:" & vbCrLf
    tips = tips & "   - 安装最新版的Microsoft XML Core Services" & vbCrLf
    tips = tips & "   - 尝试使用不同版本的XMLHTTP对象" & vbCrLf & vbCrLf
    
    tips = tips & "4. 代理服务器问题:" & vbCrLf
    tips = tips & "   - 检查系统代理设置" & vbCrLf
    tips = tips & "   - 尝试在代码中配置代理" & vbCrLf & vbCrLf
    
    tips = tips & "5. Access安全设置:" & vbCrLf
    tips = tips & "   - 检查Access宏安全级别" & vbCrLf
    tips = tips & "   - 确保启用了ActiveX控件" & vbCrLf & vbCrLf
    
    tips = tips & "如果问题仍然存在，请:" & vbCrLf
    tips = tips & "1. 运行ShowConnectionDiagnosis()获取详细诊断" & vbCrLf
    tips = tips & "2. 检查Debug窗口中的错误信息" & vbCrLf
    tips = tips & "3. 联系系统管理员" & vbCrLf
    
    Debug.Print tips
    MsgBox tips, vbInformation, "故障排除提示"
End Sub

' 修复后的登录函数
Public Function UserLoginFixed(username As String, password As String) As APIError
    On Error GoTo ErrorHandler
    
    Dim url As String
    Dim postData As String
    Dim response As String
    
    ' 使用增强版请求函数
    url = "https://lvren.cc/api/auth.php?action=login"
    postData = "{""username"":""" & username & """,""password"":""" & password & """}"
    
    ' 首先尝试HTTPS
    response = SendHttpRequestEnhanced(url, "POST", postData, True)
    
    If response = "" Then
        ' HTTPS失败，尝试HTTP
        Debug.Print "HTTPS失败，尝试HTTP连接..."
        url = "http://lvren.cc/api/auth.php?action=login"
        response = SendHttpRequestEnhanced(url, "POST", postData, False)
    End If
    
    If response = "" Then
        UserLoginFixed = APIError.NetworkError
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
        UserLoginFixed = APIError.Success
    Else
        UserLoginFixed = APIError.AuthError
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print "登录错误: " & Err.Description
    UserLoginFixed = APIError.ServerError
End Function

' 测试修复后的登录
Public Sub TestFixedLogin()
    Dim username As String
    Dim password As String
    Dim result As APIError
    
    username = InputBox("请输入用户名:", "登录测试")
    If username = "" Then Exit Sub
    
    password = InputBox("请输入密码:", "登录测试")
    If password = "" Then Exit Sub
    
    result = UserLoginFixed(username, password)
    
    Select Case result
        Case APIError.Success
            MsgBox "登录成功！" & vbCrLf & GetCurrentUserInfo(), vbInformation, "成功"
        Case APIError.AuthError
            MsgBox "用户名或密码错误", vbExclamation, "登录失败"
        Case APIError.RateLimitError
            MsgBox "请求过于频繁，请稍后再试", vbExclamation, "请求限制"
        Case APIError.NetworkError
            MsgBox "网络连接错误。请运行诊断程序检查问题。", vbExclamation, "网络错误"
            ShowConnectionDiagnosis
        Case Else
            MsgBox "登录失败，请稍后再试", vbExclamation, "未知错误"
    End Select
End Sub