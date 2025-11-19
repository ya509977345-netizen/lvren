<?php
require_once 'config.php';

header('Content-Type: application/json');

// 安全检查
$allowedIPs = ['127.0.0.1', '::1']; // 只允许本地访问
$clientIP = $_SERVER['REMOTE_ADDR'];

if (!in_array($clientIP, $allowedIPs)) {
    echo json_encode([
        'success' => false,
        'message' => '访问被拒绝'
    ]);
    exit;
}

try {
    $queueDir = __DIR__ . '/email_queue';
    $emails = [];
    
    if (is_dir($queueDir)) {
        $files = glob($queueDir . '/*.eml');
        
        foreach ($files as $file) {
            $content = file_get_contents($file);
            $emails[] = [
                'file' => basename($file),
                'timestamp' => filemtime($file),
                'date' => date('Y-m-d H:i:s', filemtime($file)),
                'content' => $content
            ];
        }
        
        // 按时间倒序排列
        usort($emails, function($a, $b) {
            return $b['timestamp'] - $a['timestamp'];
        });
    }
    
    echo json_encode([
        'success' => true,
        'count' => count($emails),
        'emails' => $emails
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => '读取邮件队列失败: ' . $e->getMessage()
    ]);
}
?>