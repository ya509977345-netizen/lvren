<?php
require_once 'config.php';

$token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiMTYiLCJleHAiOjE3NjM1MzQxNjAsImlhdCI6MTc2MzUzMDU2MH0.NaWRCc9K_o8tvEXF6IKckuP6_odEf2LMenh9CFiANT8";

echo "Testing JWT decode:\n";
$userId = verifyToken($token);
echo "Decoded userId: " . $userId . "\n";

// Test direct database query
if ($userId) {
    $database = new Database();
    $db = $database->getConnection();
    $stmt = $db->prepare("SELECT balance FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Database balance for user $userId: " . $result['balance'] . "\n";
}
?>