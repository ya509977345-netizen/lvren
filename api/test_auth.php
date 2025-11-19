<?php
require_once 'config.php';

// 模拟完整的认证流程
echo "=== Testing Complete Auth Flow ===\n";

// 1. Test login
$loginData = json_encode(['username' => 'wy123456', 'password' => 'wy654321']);

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'https://lvren.cc/api/auth.php?action=login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $loginData);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'X-API-Key: Wang869678'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$loginResponse = curl_exec($ch);
curl_close($ch);

echo "Login Response: " . $loginResponse . "\n";

$loginData = json_decode($loginResponse, true);
if (isset($loginData['token'])) {
    $token = $loginData['token'];
    echo "Extracted token: " . substr($token, 0, 30) . "...\n";
    
    // 2. Test balance query with the token
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://lvren.cc/api/wallet.php?action=balance');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'X-API-Key: Wang869678'
    ]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $balanceResponse = curl_exec($ch);
    curl_close($ch);
    
    echo "Balance Response: " . $balanceResponse . "\n";
}

echo "=== End Test ===\n";
?>