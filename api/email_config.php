<?php
/**
 * 邮件发送配置文件
 * 
 * 使用说明：
 * 1. 根据您的邮件服务商修改配置
 * 2. 确保服务器已安装并配置了邮件发送功能
 * 3. 测试邮件发送功能
 */

// 邮件配置
define('EMAIL_FROM', 'noreply@lvren.cc');           // 发件人邮箱
define('EMAIL_FROM_NAME', '软件授权系统');           // 发件人名称
define('EMAIL_REPLY_TO', 'support@lvren.cc');        // 回复邮箱

// SMTP配置（如果使用SMTP）
define('SMTP_HOST', '');                             // SMTP服务器地址
define('SMTP_PORT', 587);                            // SMTP端口
define('SMTP_USERNAME', '');                         // SMTP用户名
define('SMTP_PASSWORD', '');                         // SMTP密码
define('SMTP_ENCRYPTION', 'tls');                    // 加密方式: tls, ssl

// 常用邮件服务商配置示例：
/*
QQ邮箱:
define('SMTP_HOST', 'smtp.qq.com');
define('SMTP_PORT', 587);
define('SMTP_ENCRYPTION', 'tls');

163邮箱:
define('SMTP_HOST', 'smtp.163.com');
define('SMTP_PORT', 465);
define('SMTP_ENCRYPTION', 'ssl');

Gmail:
define('SMTP_HOST', 'smtp.gmail.com');
define('SMTP_PORT', 587);
define('SMTP_ENCRYPTION', 'tls');

阿里云邮箱:
define('SMTP_HOST', 'smtp.mxhichina.com');
define('SMTP_PORT', 587);
define('SMTP_ENCRYPTION', 'tls');
*/

// 测试邮件发送函数
function testEmailSend() {
    $testEmail = 'your-test-email@example.com'; // 修改为您的测试邮箱
    $subject = '邮件发送测试';
    $message = '这是一封测试邮件，如果您收到此邮件，说明邮件发送功能正常工作。';
    
    $headers = "From: " . EMAIL_FROM . "\r\n";
    $headers .= "Reply-To: " . EMAIL_REPLY_TO . "\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
    
    $result = mail($testEmail, $subject, $message, $headers);
    
    if ($result) {
        echo "测试邮件发送成功！请检查 " . $testEmail . " 的收件箱。";
    } else {
        echo "邮件发送失败，请检查服务器邮件配置。";
    }
}

// 检查邮件函数是否可用
function isMailFunctionAvailable() {
    return function_exists('mail');
}

// 获取邮件发送状态
function getMailStatus() {
    if (!isMailFunctionAvailable()) {
        return [
            'available' => false,
            'message' => 'PHP mail() 函数不可用',
            'solution' => '请安装并配置 sendmail 或 postfix'
        ];
    }
    
    // 检查是否配置了SMTP
    if (empty(SMTP_HOST)) {
        return [
            'available' => true,
            'method' => 'PHP mail()',
            'message' => '使用 PHP mail() 函数发送邮件',
            'note' => '请确保服务器已配置邮件发送服务'
        ];
    }
    
    return [
        'available' => true,
        'method' => 'SMTP',
        'message' => '使用 SMTP 发送邮件',
        'config' => [
            'host' => SMTP_HOST,
            'port' => SMTP_PORT,
            'encryption' => SMTP_ENCRYPTION
        ]
    ];
}
?>