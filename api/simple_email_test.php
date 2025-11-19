<?php
// 简化的邮件测试脚本
header('Content-Type: application/json');

try {
    $to = 'test@example.com';
    $subject = '邮件测试 - ' . date('Y-m-d H:i:s');
    $message = '这是一封测试邮件，发送时间：' . date('Y-m-d H:i:s');
    
    // 创建邮件队列目录
    $queueDir = __DIR__ . '/email_queue';
    if (!is_dir($queueDir)) {
        mkdir($queueDir, 0755, true);
    }
    
    // 保存邮件到文件
    $filename = $queueDir . '/test_' . date('Y-m-d_H-i-s') . '.eml';
    $emailContent = "To: $to\n";
    $emailContent .= "Subject: $subject\n";
    $emailContent .= "Date: " . date('r') . "\n";
    $emailContent .= "From: noreply@lvren.cc\n\n";
    $emailContent .= $message;
    
    $result = file_put_contents($filename, $emailContent);
    
    if ($result !== false) {
        echo json_encode([
            'success' => true,
            'message' => '测试邮件已保存到文件',
            'file' => basename($filename),
            'path' => $filename,
            'content' => $emailContent
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => '保存邮件文件失败'
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => '错误: ' . $e->getMessage()
    ]);
}
?>