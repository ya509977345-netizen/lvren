# 邮件发送功能设置指南

## 概述

忘记密码功能现在支持真实邮件发送。系统已配置了完整的邮件发送流程，包括：

1. **密码重置请求处理** - 生成重置令牌
2. **邮件发送功能** - 发送重置链接到用户邮箱
3. **密码重置页面** - 用户设置新密码
4. **邮件配置测试** - 验证邮件发送功能

## 功能特性

### 🎯 核心功能
- ✅ 生成安全的重置令牌（32位随机字符串）
- ✅ 令牌1小时自动过期
- ✅ 防止邮箱枚举攻击（不透露邮箱是否存在）
- ✅ 美观的HTML邮件模板
- ✅ 密码强度验证
- ✅ 完整的错误处理和日志记录

### 📧 邮件发送方式
- **主要方式**: PHP `mail()` 函数
- **支持扩展**: 可轻松集成 PHPMailer、SendGrid 等服务
- **备用方案**: 支持SMTP配置

## 文件结构

```
/api/
├── auth.php              # 认证API（包含忘记密码功能）
├── email_config.php      # 邮件配置文件
├── email_status.php      # 邮件状态检查API
├── email_test.php        # 邮件测试API
└── ...

/reset-password.html     # 密码重置页面
/email-test.html         # 邮件配置测试页面
/EMAIL_SETUP_GUIDE.md    # 本指南
```

## 使用方法

### 1. 用户使用流程

1. **请求重置密码**
   ```vba
   ForgotPassword "user@example.com"
   ```

2. **检查邮箱**
   - 用户收到重置邮件
   - 点击邮件中的重置链接

3. **设置新密码**
   - 访问重置链接页面
   - 输入新密码并确认

### 2. 管理员配置流程

1. **检查邮件状态**
   - 访问 `https://lvren.cc/email-test.html`
   - 查看当前邮件发送状态

2. **发送测试邮件**
   - 在测试页面输入邮箱地址
   - 验证邮件是否正常发送

3. **配置邮件服务**（如需要）
   - 修改 `api/email_config.php` 中的配置
   - 安装和配置服务器邮件服务

## 邮件服务配置

### 方案1: 使用系统邮件服务（推荐）

**CentOS/RHEL:**
```bash
sudo yum install sendmail
sudo systemctl start sendmail
sudo systemctl enable sendmail
```

**Ubuntu/Debian:**
```bash
sudo apt-get install sendmail
sudo systemctl start sendmail
sudo systemctl enable sendmail
```

**PHP配置 (php.ini):**
```ini
[mail function]
sendmail_path = /usr/sbin/sendmail -t -i
```

### 方案2: 使用第三方邮件服务

如果系统邮件服务不可用，推荐使用第三方服务：

#### SendGrid
```php
// 替换 sendPasswordResetEmail() 方法
private function sendPasswordResetEmail($email, $username, $resetToken) {
    $apiKey = 'YOUR_SENDGRID_API_KEY';
    $url = 'https://api.sendgrid.com/v3/mail/send';
    
    $resetLink = "https://lvren.cc/reset-password?token=" . $resetToken;
    
    $data = [
        'personalizations' => [[
            'to' => [['email' => $email]],
            'subject' => '密码重置请求'
        ]],
        'from' => ['email' => 'noreply@lvren.cc', 'name' => '软件授权系统'],
        'content' => [[
            'type' => 'text/plain',
            'value' => $this->getPasswordResetEmailText($username, $resetToken)
        ]]
    ];
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $apiKey,
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return $httpCode === 202;
}
```

## 安全特性

### 🔒 令牌安全
- 使用 `random_bytes(32)` 生成安全随机令牌
- 令牌存储在数据库中，1小时后自动过期
- 使用后立即失效，防止重复使用

### 🛡️ 防攻击机制
- 统一的响应消息，防止邮箱枚举
- 速率限制，防止暴力攻击
- 详细的日志记录，便于安全审计

### 🔐 密码安全
- 使用 `password_hash()` 和 `password_verify()` 
- 强制密码长度至少6个字符
- 建议使用复杂密码

## 监控和日志

### 日志记录
系统会记录以下操作：
- 密码重置请求（成功/失败）
- 邮件发送状态
- 密码重置成功/失败
- 令牌验证结果

### 监控指标
- 忘记密码请求频率
- 邮件发送成功率
- 密码重置完成率
- 异常错误率

## 故障排除

### 常见问题

**Q: 用户没有收到重置邮件？**
- 检查垃圾邮件文件夹
- 验证邮箱地址是否正确
- 测试邮件发送功能

**Q: 邮件发送失败？**
- 检查服务器邮件服务状态
- 验证PHP邮件配置
- 查看错误日志

**Q: 重置链接无效？**
- 检查令牌是否过期（1小时有效期）
- 验证链接完整性
- 检查数据库中的令牌记录

### 调试工具

1. **邮件测试页面**: `https://lvren.cc/email-test.html`
2. **系统日志**: 检查服务器邮件和PHP错误日志
3. **数据库查询**: 验证重置令牌是否正确存储

## API 接口

### 忘记密码
```
POST /api/auth.php?action=forgot-password
Content-Type: application/json
X-API-Key: Wang869678

{
  "email": "user@example.com"
}
```

### 重置密码
```
POST /api/auth.php?action=reset-password
Content-Type: application/json
X-API-Key: Wang869678

{
  "token": "reset_token_here",
  "new_password": "new_password_here"
}
```

### 邮件状态检查
```
GET /api/email_status.php
X-API-Key: Wang869678
```

### 邮件发送测试
```
POST /api/email_test.php
Content-Type: application/json
X-API-Key: Wang869678

{
  "to": "test@example.com",
  "subject": "测试邮件",
  "message": "这是一封测试邮件"
}
```

## 升级建议

### 短期改进
1. 添加邮件模板自定义功能
2. 支持批量邮件发送
3. 添加邮件发送队列

### 长期规划
1. 集成专业邮件服务（SendGrid、Mailgun）
2. 添加邮件打开率和点击率追踪
3. 支持多语言邮件模板
4. 添加邮件发送统计和报表

---

**注意**: 生产环境使用前，请务必：
1. 测试邮件发送功能
2. 配置正确的邮件服务
3. 设置适当的速率限制
4. 监控邮件发送状态
5. 备份相关配置