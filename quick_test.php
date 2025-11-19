<?php
/**
 * 乐人软件API快速测试脚本
 * 直接通过浏览器访问进行测试
 */

// 配置
$base_url = 'https://lvren.cc/api';

function testAPI($url, $method = 'GET', $data = null, $headers = []) {
    $ch = curl_init();
    
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, true);
    
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }
    }
    
    if (!empty($headers)) {
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    }
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    
    $header = substr($response, 0, $header_size);
    $body = substr($response, $header_size);
    
    curl_close($ch);
    
    return [
        'http_code' => $http_code,
        'header' => $header,
        'body' => $body,
        'json' => json_decode($body, true)
    ];
}

function printResult($title, $result) {
    echo "<div style='border: 1px solid #ccc; margin: 10px; padding: 10px;'>";
    echo "<h3>$title</h3>";
    echo "<p><strong>HTTP状态码:</strong> {$result['http_code']}</p>";
    
    if ($result['json']) {
        echo "<p><strong>响应数据:</strong></p>";
        echo "<pre>" . json_encode($result['json'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "</pre>";
    } else {
        echo "<p><strong>响应内容:</strong> " . htmlspecialchars($result['body']) . "</p>";
    }
    echo "</div>";
}

// 开始测试
echo "<h1>乐人软件API快速测试</h1>";
echo "<p>测试时间: " . date('Y-m-d H:i:s') . "</p>";

// 1. 测试数据库连接
$result = testAPI($base_url . '/config.php');
printResult('数据库连接测试', $result);

// 2. 测试注册接口
$register_data = [
    'username' => 'test_' . time(),
    'password' => 'test123456',
    'email' => 'test' . time() . '@example.com'
];

$result = testAPI($base_url . '/auth.php?action=register', 'POST', $register_data, [
    'Content-Type: application/json'
]);
printResult('用户注册测试', $result);

// 如果注册成功，保存用户信息
if ($result['json'] && $result['json']['success']) {
    $user_data = $register_data;
    $user_data['user_id'] = $result['json']['user_id'];
    
    // 3. 测试登录接口
    $login_data = [
        'username' => $user_data['username'],
        'password' => $user_data['password']
    ];
    
    $result = testAPI($base_url . '/auth.php?action=login', 'POST', $login_data, [
        'Content-Type: application/json'
    ]);
    printResult('用户登录测试', $result);
    
    if ($result['json'] && $result['json']['success']) {
        $token = $result['json']['token'];
        
        // 4. 测试Token验证
        $result = testAPI($base_url . '/auth.php?action=verify', 'POST', null, [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $token
        ]);
        printResult('Token验证测试', $result);
        
        // 5. 测试余额查询
        $result = testAPI($base_url . '/wallet.php?action=balance', 'GET', null, [
            'Authorization: Bearer ' . $token
        ]);
        printResult('余额查询测试', $result);
        
        // 6. 测试充值
        $recharge_data = [
            'amount' => 100.0,
            'payment_method' => 'test'
        ];
        
        $result = testAPI($base_url . '/wallet.php?action=recharge', 'POST', $recharge_data, [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $token
        ]);
        printResult('充值测试', $result);
        
        // 7. 测试授权检查
        $result = testAPI($base_url . '/license.php?action=check&software_id=test_app', 'GET', null, [
            'Authorization: Bearer ' . $token
        ]);
        printResult('授权检查测试', $result);
    }
}

// 错误测试
echo "<h2>错误处理测试</h2>";

// 测试空数据
$result = testAPI($base_url . '/auth.php?action=login', 'POST', [], [
    'Content-Type: application/json'
]);
printResult('空数据登录测试', $result);

// 测试错误密码
$wrong_data = [
    'username' => 'nonexistent',
    'password' => 'wrongpassword'
];
$result = testAPI($base_url . '/auth.php?action=login', 'POST', $wrong_data, [
    'Content-Type: application/json'
]);
printResult('错误凭证测试', $result);

// 测试无效接口
$result = testAPI($base_url . '/auth.php?action=nonexistent', 'GET');
printResult('无效接口测试', $result);

echo "<h2>测试完成</h2>";
echo "<p>所有API接口测试完成。查看上面的测试结果确认接口状态。</p>";
?>