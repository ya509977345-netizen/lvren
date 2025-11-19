<?php
require_once 'config.php';

// 创建一个新的测试token
$testToken = generateToken(16);
echo "Generated test token: " . $testToken . "\n";

// 验证这个token
$decodedUserId = verifyToken($testToken);
echo "Verified user ID: " . $decodedUserId . "\n";

// 使用这个token测试balance API
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'https://lvren.cc/api/wallet.php?action=balance');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $testToken,
    'X-API-Key: Wang869678'
]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Status: " . $httpCode . "\n";
echo "Balance Response: " . $response . "\n";
?>