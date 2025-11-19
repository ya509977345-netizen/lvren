<?php
require_once 'config.php';
require_once 'email_sender.php';

header('Content-Type: application/json');

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['to']) || !filter_var($input['to'], FILTER_VALIDATE_EMAIL)) {
        echo json_encode([
            'success' => false,
            'message' => '无效的邮箱地址'
        ]);
        exit;
    }
    
    $to = $input['to'];
    $subject = $input['subject'] ?? '邮件发送测试';
    $message = $input['message'] ?? '这是一封测试邮件，用于验证邮件发送功能是否正常工作。';
    
    // 使用新的邮件发送器
    $emailSender = new EmailSender();
    $sent = $emailSender->send($to, $subject, $message);
    
    if ($sent) {
        echo json_encode([
            'success' => true,
            'message' => '测试邮件发送成功',
            'to' => $to,
            'subject' => $subject,
            'sent_at' => date('Y-m-d H:i:s')
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => '邮件发送失败，请配置邮件服务',
            'recommendation' => '请配置第三方邮件API或安装系统邮件服务'
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => '邮件发送异常: ' . $e->getMessage()
    ]);
}
?>