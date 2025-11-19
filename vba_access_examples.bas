' Access VBA API集成示例
' 演示如何在Access VBA应用程序中使用乐人软件API
' 需要在VBA编辑器中添加引用：Microsoft XML, v6.0

Option Explicit

' ==================== 基础设置和全局变量 ====================

' API服务器地址 - 根据实际情况修改
Private Const API_BASE_URL As String = "https://lvren.cc/api/"
Private Const API_KEY As String = "Wang869678"

' 全局变量存储用户登录信息
Private g_userToken As String
Private g_userId As Long
Private g_username As String
Private g_balance As Double

' ==================== 用户登录相关示例 ====================

' 示例1：简单的用户登录表单集成
Public Sub LoginUser(txtUsername As Control, txtPassword As Control, lblStatus As Label)
    On Error GoTo ErrorHandler
    
    lblStatus.Caption = "正在登录..."
    lblStatus.ForeColor = RGB(0, 0, 255)  ' 蓝色
    
    Dim result As APIError
    result = UserLogin(txtUsername.Value, txtPassword.Value)
    
    Select Case result
        Case APIError.Success
            lblStatus.Caption = "登录成功！欢迎，" & g_username
            lblStatus.ForeColor = RGB(0, 128, 0)  ' 绿色
            
            ' 登录成功后，可以启用其他功能按钮
            EnableApplicationFeatures True
            
            ' 记录登录成功日志到Access表
            LogUserActivity g_userId, "登录", "用户登录成功"
            
        Case APIError.AuthError
            lblStatus.Caption = "用户名或密码错误，请重试"
            lblStatus.ForeColor = RGB(255, 0, 0)  ' 红色
            txtPassword.SetFocus
            txtPassword.SelStart = 0
            txtPassword.SelLength = Len(txtPassword.Value)
            
        Case APIError.RateLimitError
            lblStatus.Caption = "请求过于频繁，请稍后再试"
            lblStatus.ForeColor = RGB(255, 128, 0)  ' 橙色
            
        Case APIError.NetworkError
            lblStatus.Caption = "网络连接错误，请检查网络设置"
            lblStatus.ForeColor = RGB(255, 0, 0)  ' 红色
            
        Case APIError.ServerError
            lblStatus.Caption = "服务器错误，请稍后再试"
            lblStatus.ForeColor = RGB(255, 0, 0)  ' 红色
            
        Case Else
            lblStatus.Caption = "未知错误，请联系管理员"
            lblStatus.ForeColor = RGB(255, 0, 0)  ' 红色
    End Select
    
    Exit Sub
    
ErrorHandler:
    lblStatus.Caption = "系统错误: " & Err.Description
    lblStatus.ForeColor = RGB(255, 0, 0)  ' 红色
    LogUserActivity 0, "登录错误", Err.Description
End Sub

' 示例2：用户注册表单集成
Public Sub RegisterUser(txtUsername As Control, txtPassword As Control, txtConfirmPassword As Control, txtEmail As Control, lblStatus As Label)
    On Error GoTo ErrorHandler
    
    ' 前端验证
    If Trim(txtUsername.Value) = "" Then
        lblStatus.Caption = "请输入用户名"
        lblStatus.ForeColor = RGB(255, 0, 0)
        txtUsername.SetFocus
        Exit Sub
    End If
    
    If Len(txtUsername.Value) < 3 Then
        lblStatus.Caption = "用户名至少需要3个字符"
        lblStatus.ForeColor = RGB(255, 0, 0)
        txtUsername.SetFocus
        Exit Sub
    End If
    
    If txtPassword.Value <> txtConfirmPassword.Value Then
        lblStatus.Caption = "两次输入的密码不一致"
        lblStatus.ForeColor = RGB(255, 0, 0)
        txtPassword.SetFocus
        Exit Sub
    End If
    
    If Len(txtPassword.Value) < 6 Then
        lblStatus.Caption = "密码至少需要6个字符"
        lblStatus.ForeColor = RGB(255, 0, 0)
        txtPassword.SetFocus
        Exit Sub
    End If
    
    If InStr(txtEmail.Value, "@") = 0 Or InStr(txtEmail.Value, ".") = 0 Then
        lblStatus.Caption = "请输入有效的邮箱地址"
        lblStatus.ForeColor = RGB(255, 0, 0)
        txtEmail.SetFocus
        Exit Sub
    End If
    
    lblStatus.Caption = "正在注册..."
    lblStatus.ForeColor = RGB(0, 0, 255)
    
    Dim result As APIError
    result = UserRegister(txtUsername.Value, txtPassword.Value, txtEmail.Value)
    
    Select Case result
        Case APIError.Success
            lblStatus.Caption = "注册成功！您现在可以登录了"
            lblStatus.ForeColor = RGB(0, 128, 0)
            
            ' 清空表单
            txtUsername.Value = ""
            txtPassword.Value = ""
            txtConfirmPassword.Value = ""
            txtEmail.Value = ""
            
            ' 跳转到登录标签页（如果使用标签页）
            ' Me.TabControl1.Value = 0
            
        Case APIError.AuthError
            lblStatus.Caption = "用户名已存在或邮箱已被使用"
            lblStatus.ForeColor = RGB(255, 0, 0)
            txtUsername.SetFocus
            
        Case APIError.ValidationError
            lblStatus.Caption = "输入数据格式不正确，请检查"
            lblStatus.ForeColor = RGB(255, 0, 0)
            
        Case APIError.RateLimitError
            lblStatus.Caption = "请求过于频繁，请稍后再试"
            lblStatus.ForeColor = RGB(255, 128, 0)
            
        Case Else
            lblStatus.Caption = "注册失败，请稍后再试"
            lblStatus.ForeColor = RGB(255, 0, 0)
    End Select
    
    Exit Sub
    
ErrorHandler:
    lblStatus.Caption = "系统错误: " & Err.Description
    lblStatus.ForeColor = RGB(255, 0, 0)
End Sub

' ==================== 用户状态和余额显示示例 ====================

' 示例3：显示用户状态和余额
Public Sub UpdateUserStatusDisplay(lblUserInfo As Label, lblBalance As Label, btnRecharge As CommandButton)
    On Error Resume Next
    
    If IsUserLoggedIn() Then
        ' 显示用户信息
        lblUserInfo.Caption = "当前用户: " & g_username & " (ID: " & g_userId & ")"
        lblBalance.Caption = "当前余额: " & Format(g_balance, "0.00") & " 元"
        
        ' 启用充值按钮
        btnRecharge.Enabled = True
        
        ' 更新余额（从服务器获取最新数据）
        Dim currentBalance As Double
        currentBalance = GetUserBalance()
        
        If currentBalance >= 0 Then
            g_balance = currentBalance
            lblBalance.Caption = "当前余额: " & Format(g_balance, "0.00") & " 元"
        Else
            lblBalance.Caption = "余额获取失败"
        End If
    Else
        ' 用户未登录
        lblUserInfo.Caption = "未登录"
        lblBalance.Caption = "请先登录"
        btnRecharge.Enabled = False
    End If
End Sub

' 示例4：定期自动更新余额
Public Sub AutoUpdateBalance(intervalMinutes As Integer)
    On Error Resume Next
    
    ' 这个函数可以通过定时器调用
    If IsUserLoggedIn() Then
        Dim currentBalance As Double
        currentBalance = GetUserBalance()
        
        If currentBalance >= 0 Then
            g_balance = currentBalance
            ' 更新界面上显示余额的控件
            ' Me.lblBalance.Caption = "当前余额: " & Format(g_balance, "0.00") & " 元"
            
            ' 如果余额低于阈值，可以通知用户
            If g_balance < 10 Then
                MsgBox "您的余额已低于10元，请及时充值", vbExclamation, "余额提醒"
            End If
        End If
    End If
End Sub

' ==================== 充值功能示例 ====================

' 示例5：用户充值对话框
Public Function ShowRechargeDialog() As Boolean
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录后再进行充值操作", vbExclamation, "需要登录"
        ShowRechargeDialog = False
        Exit Function
    End If
    
    ' 创建一个简单的输入对话框
    Dim amount As String
    amount = InputBox("请输入充值金额（元）:", "账户充值", "50")
    
    If amount = "" Then
        ShowRechargeDialog = False
        Exit Function
    End If
    
    Dim rechargeAmount As Double
    rechargeAmount = Val(amount)
    
    If rechargeAmount <= 0 Then
        MsgBox "充值金额必须大于0", vbExclamation, "无效金额"
        ShowRechargeDialog = False
        Exit Function
    End If
    
    If rechargeAmount > 10000 Then
        MsgBox "单次充值金额不能超过10000元", vbExclamation, "金额超限"
        ShowRechargeDialog = False
        Exit Function
    End If
    
    ' 选择支付方式
    Dim paymentMethod As String
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
            ShowRechargeDialog = False
            Exit Function
    End Select
    
    ' 执行充值
    Dim result As APIError
    result = UserRecharge(rechargeAmount, paymentMethod)
    
    Select Case result
        Case APIError.Success
            MsgBox "充值成功！金额: " & Format(rechargeAmount, "0.00") & " 元", vbInformation, "充值成功"
            
            ' 更新余额
            g_balance = g_balance + rechargeAmount
            ' UpdateUserStatusDisplay ' 调用更新显示函数
            
            ' 记录充值日志
            LogUserActivity g_userId, "充值", "充值金额: " & Format(rechargeAmount, "0.00") & " 元，支付方式: " & paymentMethod
            
            ShowRechargeDialog = True
            
        Case APIError.RateLimitError
            MsgBox "操作过于频繁，请稍后再试", vbExclamation, "请求限制"
            ShowRechargeDialog = False
            
        Case APIError.ValidationError
            MsgBox "充值数据验证失败", vbExclamation, "数据错误"
            ShowRechargeDialog = False
            
        Case Else
            MsgBox "充值失败，请稍后再试", vbExclamation, "充值失败"
            ShowRechargeDialog = False
    End Select
    
    Exit Function
    
ErrorHandler:
    MsgBox "充值过程中发生错误: " & Err.Description, vbCritical, "系统错误"
    ShowRechargeDialog = False
End Function

' ==================== 软件授权和功能使用示例 ====================

' 示例6：检查软件授权并使用功能
Public Function UseSoftwareFeature(featureName As String, featureCost As Double, Optional parameter1 As Variant, Optional parameter2 As Variant) As Boolean
    On Error GoTo ErrorHandler
    
    ' 检查用户是否登录
    If Not IsUserLoggedIn() Then
        MsgBox "使用此功能需要先登录", vbExclamation, "需要登录"
        UseSoftwareFeature = False
        Exit Function
    End If
    
    ' 检查软件授权
    If Not CheckLicense("main_app") Then
        MsgBox "您没有使用此功能的授权，请先购买授权", vbExclamation, "授权无效"
        UseSoftwareFeature = False
        Exit Function
    End If
    
    ' 检查余额是否足够
    Dim currentBalance As Double
    currentBalance = GetUserBalance()
    
    If currentBalance < featureCost Then
        MsgBox "余额不足！" & vbCrLf & _
               "当前余额: " & Format(currentBalance, "0.00") & " 元" & vbCrLf & _
               "需要费用: " & Format(featureCost, "0.00") & " 元" & vbCrLf & vbCrLf & _
               "请先充值后再使用此功能", vbExclamation, "余额不足"
        UseSoftwareFeature = False
        Exit Function
    End If
    
    ' 询问用户确认
    Dim confirmResult As VbMsgBoxResult
    confirmResult = MsgBox("使用" & featureName & "功能将扣除" & Format(featureCost, "0.00") & "元" & vbCrLf & _
                         "当前余额: " & Format(currentBalance, "0.00") & " 元" & vbCrLf & vbCrLf & _
                         "确认使用此功能吗？", vbQuestion + vbYesNo, "使用确认")
    
    If confirmResult = vbNo Then
        UseSoftwareFeature = False
        Exit Function
    End If
    
    ' 扣费
    Dim result As APIError
    result = DeductBalance(featureCost, "使用" & featureName & "功能")
    
    If result = APIError.Success Then
        ' 更新余额
        g_balance = g_balance - featureCost
        ' UpdateUserStatusDisplay ' 调用更新显示函数
        
        ' 执行实际功能（这里只是示例）
        ' Select Case featureName
        '     Case "数据分析"
        '         ' 执行数据分析功能
        '     Case "报告生成"
        '         ' 执行报告生成功能
        ' End Select
        
        MsgBox "功能使用成功！已扣除" & Format(featureCost, "0.00") & "元", vbInformation, "使用成功"
        
        ' 记录功能使用日志
        LogUserActivity g_userId, "功能使用", "使用" & featureName & "功能，费用: " & Format(featureCost, "0.00") & "元"
        
        UseSoftwareFeature = True
    Else
        Select Case result
            Case APIError.RateLimitError
                MsgBox "操作过于频繁，请稍后再试", vbExclamation, "请求限制"
            Case APIError.AuthError
                MsgBox "余额不足或账户异常", vbExclamation, "账户错误"
            Case Else
                MsgBox "功能使用失败，请稍后再试", vbExclamation, "使用失败"
        End Select
        
        UseSoftwareFeature = False
    End If
    
    Exit Function
    
ErrorHandler:
    MsgBox "功能使用过程中发生错误: " & Err.Description, vbCritical, "系统错误"
    UseSoftwareFeature = False
End Function

' 示例7：软件授权管理界面
Public Sub ManageSoftwareLicenses(lstLicenses As ListBox, btnCreateLicense As CommandButton, btnRenewLicense As CommandButton)
    On Error GoTo ErrorHandler
    
    If Not IsUserLoggedIn() Then
        MsgBox "请先登录后再管理授权", vbExclamation, "需要登录"
        Exit Sub
    End If
    
    ' 清空列表
    lstLicenses.RowSource = ""
    
    ' 这里应该调用API获取用户授权列表
    ' 由于我们的VBA示例中没有完整实现，这里只是示例代码结构
    ' 实际使用时需要补充API调用和解析逻辑
    
    ' 创建新授权
    If btnCreateLicense.Value Then
        Dim softwareId As String
        Dim durationDays As Integer
        Dim maxDevices As Integer
        
        softwareId = InputBox("请输入软件ID:", "创建授权", "main_app")
        If softwareId = "" Then Exit Sub
        
        durationDays = Val(InputBox("请输入授权天数:", "创建授权", "30"))
        If durationDays <= 0 Then Exit Sub
        
        maxDevices = Val(InputBox("请输入最大设备数:", "创建授权", "1"))
        If maxDevices <= 0 Then Exit Sub
        
        Dim result As APIError
        result = CreateLicense(softwareId, durationDays, maxDevices)
        
        Select Case result
            Case APIError.Success
                MsgBox "授权创建成功！", vbInformation, "创建成功"
                ' 刷新授权列表
            Case APIError.RateLimitError
                MsgBox "操作过于频繁，请稍后再试", vbExclamation, "请求限制"
            Case Else
                MsgBox "授权创建失败，请稍后再试", vbExclamation, "创建失败"
        End Select
    End If
    
    ' 续期授权
    If btnRenewLicense.Value Then
        If lstLicenses.ListIndex = -1 Then
            MsgBox "请先选择一个授权", vbExclamation, "选择授权"
            Exit Sub
        End If
        
        Dim licenseId As Long
        licenseId = Val(lstLicenses.Column(0, lstLicenses.ListIndex))
        
        Dim extendDays As Integer
        extendDays = Val(InputBox("请输入要续期的天数:", "续期授权", "15"))
        If extendDays <= 0 Then Exit Sub
        
        ' 这里应该调用续期API
        ' 由于示例简化，这里只是显示成功消息
        MsgBox "授权续期成功！", vbInformation, "续期成功"
        
        ' 刷新授权列表
    End If
    
    Exit Sub
    
ErrorHandler:
    MsgBox "授权管理过程中发生错误: " & Err.Description, vbCritical, "系统错误"
End Sub

' ==================== 应用程序集成和辅助函数 ====================

' 示例8：应用程序启动时的初始化
Public Sub InitializeApplication()
    On Error GoTo ErrorHandler
    
    ' 检查API连接
    If Not TestAPIConnection() Then
        MsgBox "无法连接到服务器，请检查网络连接。" & vbCrLf & _
               "部分功能可能无法正常使用。", vbExclamation, "连接警告"
    End If
    
    ' 尝试使用存储的Token自动登录
    ' 这里可以从注册表或加密文件中读取之前存储的Token
    ' Dim savedToken As String
    ' savedToken = GetSetting("MyApp", "Auth", "Token", "")
    ' 
    ' If savedToken <> "" Then
    '     g_userToken = savedToken
    '     
    '     ' 验证Token是否仍然有效
    '     If VerifyToken() = APIError.Success Then
    '         ' Token有效，获取用户信息
    '         ' 这里需要实现获取用户信息的API调用
    '         EnableApplicationFeatures True
    '     Else
    '         ' Token无效，清除它
    '         g_userToken = ""
    '         DeleteSetting "MyApp", "Auth", "Token"
    '         EnableApplicationFeatures False
    '     End If
    ' Else
    '     EnableApplicationFeatures False
    ' End If
    
    Exit Sub
    
ErrorHandler:
    MsgBox "应用程序初始化失败: " & Err.Description, vbCritical, "初始化错误"
End Sub

' 示例9：启用/禁用应用程序功能
Private Sub EnableApplicationFeatures(enable As Boolean)
    On Error Resume Next
    
    ' 启用或禁用需要登录的功能
    ' Me.btnFeature1.Enabled = enable
    ' Me.btnFeature2.Enabled = enable
    ' Me.btnRecharge.Enabled = enable
    ' Me.tabAdvanced.Enabled = enable
    
    ' 显示/隐藏登录面板
    ' Me.pnlLogin.Visible = Not enable
    ' Me.pnlMain.Visible = enable
End Sub

' 示例10：记录用户活动到Access表
Private Sub LogUserActivity(userId As Long, action As String, description As String)
    On Error Resume Next
    
    Dim db As Database
    Dim rs As Recordset
    
    Set db = CurrentDb()
    
    ' 检查用户活动表是否存在，不存在则创建
    On Error Resume Next
    Set rs = db.OpenRecordset("SELECT * FROM UserActivityLog WHERE 1=0", dbOpenDynaset)
    If Err.Number <> 0 Then
        ' 表不存在，创建它
        db.Execute "CREATE TABLE UserActivityLog (" & _
                  "ID AUTOINCREMENT PRIMARY KEY, " & _
                  "UserID LONG, " & _
                  "Action TEXT(50), " & _
                  "Description MEMO, " & _
                  "LogTime DATETIME DEFAULT NOW())"
        Set rs = db.OpenRecordset("SELECT * FROM UserActivityLog WHERE 1=0", dbOpenDynaset)
    End If
    On Error GoTo ErrorHandler
    
    ' 添加新记录
    rs.AddNew
    rs!UserID = userId
    rs!Action = action
    rs!Description = description
    ' LogTime字段有默认值，不需要设置
    rs.Update
    
    rs.Close
    db.Close
    
    Exit Sub
    
ErrorHandler:
    Debug.Print "记录用户活动失败: " & Err.Description
    If Not rs Is Nothing Then rs.Close
    If Not db Is Nothing Then db.Close
End Sub

' ==================== 表单事件示例 ====================

' 示例11：主窗体加载事件
Private Sub Form_Load()
    ' 初始化应用程序
    InitializeApplication
    
    ' 更新用户状态显示
    ' UpdateUserStatusDisplay Me.lblUserInfo, Me.lblBalance, Me.btnRecharge
End Sub

' 示例12：窗体卸载事件
Private Sub Form_Unload(Cancel As Integer)
    ' 清理资源
    UserLogout
    
    ' 可以选择保存Token以便下次自动登录
    ' If g_userToken <> "" Then
    '     SaveSetting "MyApp", "Auth", "Token", g_userToken
    ' End If
End Sub

' 示例13：登录按钮点击事件
Private Sub btnLogin_Click()
    ' LoginUser Me.txtUsername, Me.txtPassword, Me.lblLoginStatus
End Sub

' 示例14：注册按钮点击事件
Private Sub btnRegister_Click()
    ' RegisterUser Me.txtRegUsername, Me.txtRegPassword, Me.txtRegConfirmPassword, Me.txtRegEmail, Me.lblRegStatus
End Sub

' 示例15：充值按钮点击事件
Private Sub btnRecharge_Click()
    If ShowRechargeDialog() Then
        ' 更新界面显示
        ' UpdateUserStatusDisplay Me.lblUserInfo, Me.lblBalance, Me.btnRecharge
    End If
End Sub

' 示例16：功能按钮点击事件
Private Sub btnFeatureDataAnalysis_Click()
    If UseSoftwareFeature("数据分析", 5.0) Then
        ' 执行数据分析功能
        MsgBox "数据分析功能已执行", vbInformation, "功能完成"
    End If
End Sub

' 示例17：刷新余额按钮点击事件
Private Sub btnRefreshBalance_Click()
    ' UpdateUserStatusDisplay Me.lblUserInfo, Me.lblBalance, Me.btnRecharge
End Sub

' 示例18：定时器事件（用于定期更新余额）
Private Sub tmrAutoUpdate_Timer()
    ' 每5分钟更新一次余额
    ' AutoUpdateBalance 5
End Sub

' ==================== 完整的VBA示例窗体 ====================

' 以下是一个完整的登录窗体示例代码
' 可以在Access中创建一个新窗体，然后添加以下控件：
' - txtUsername (文本框)
' - txtPassword (文本框)
' - btnLogin (命令按钮)
' - btnRegister (命令按钮)
' - lblStatus (标签)
' - chkRememberMe (复选框)

Private Sub btnLogin_Click()
    LoginUser Me.txtUsername, Me.txtPassword, Me.lblStatus
    
    ' 如果登录成功，可以选择记住登录状态
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
    Dim savedUsername As String
    
    savedToken = GetSetting("MyApp", "Auth", "Token", "")
    savedUsername = GetSetting("MyApp", "Auth", "Username", "")
    
    If savedToken <> "" Then
        g_userToken = savedToken
        
        If VerifyToken() = APIError.Success Then
            g_username = savedUsername
            Me.lblStatus.Caption = "已自动登录: " & g_username
            Me.lblStatus.ForeColor = RGB(0, 128, 0)
            
            ' 打开主窗体
            DoCmd.OpenForm "frmMain"
            DoCmd.Close acForm, Me.Name
        Else
            ' Token无效，清除它
            DeleteSetting "MyApp", "Auth", "Token"
            DeleteSetting "MyApp", "Auth", "Username"
        End If
    End If
End Sub