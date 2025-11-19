<?php
require_once 'config.php';
require_once 'email_sender.php';

header('Content-Type: application/json');

try {
    $emailSender = new EmailSender();
    $status = $emailSender->getStatus();
    echo json_encode($status);
} catch (Exception $e) {
    echo json_encode([
        'available' => false,
        'message' => '检查邮件状态时出错: ' . $e->getMessage()
    ]);
}
?>