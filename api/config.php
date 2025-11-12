<?php
// 数据库配置 - 宝塔面板MySQL配置
define('DB_HOST', 'localhost');
define('DB_USER', '	lvren-user');
define('DB_PASS', 'fDDCN5ryLw2W4fRi');
define('DB_NAME', 'lvren-user');

// API配置 - 设置一个安全的API密钥
define('API_KEY', 'Wang869678');
define('TOKEN_EXPIRE', 3600); // 1小时

// 错误报告设置
error_reporting(0);
ini_set('display_errors', 0);

// 跨域设置
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// 设置响应头
header('Content-Type: application/json; charset=utf-8');

// 数据库连接类
class Database {
    private $connection;
    
    public function __construct() {
        try {
            $this->connection = new PDO("mysql:host=".DB_HOST.";dbname=".DB_NAME.";charset=utf8", DB_USER, DB_PASS);
            $this->connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $e) {
            $this->sendError('数据库连接失败: ' . $e->getMessage());
        }
    }
    
    public function getConnection() {
        return $this->connection;
    }
    
    private function sendError($message) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $message]);
        exit;
    }
}

// 工具函数
function generateToken($user_id) {
    $payload = [
        'user_id' => $user_id,
        'iat' => time(),
        'exp' => time() + TOKEN_EXPIRE
    ];
    return base64_encode(json_encode($payload));
}

function verifyToken($token) {
    try {
        $payload = json_decode(base64_decode($token), true);
        if (!$payload || !isset($payload['exp']) || $payload['exp'] < time()) {
            return false;
        }
        return $payload['user_id'];
    } catch (Exception $e) {
        return false;
    }
}

function validateApiKey($api_key) {
    return $api_key === API_KEY;
}

function sanitizeInput($input) {
    if (is_array($input)) {
        return array_map('sanitizeInput', $input);
    }
    return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
}

function getAuthorizationHeader() {
    $headers = null;
    if (isset($_SERVER['Authorization'])) {
        $headers = trim($_SERVER['Authorization']);
    } elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
    } elseif (function_exists('apache_request_headers')) {
        $requestHeaders = apache_request_headers();
        $requestHeaders = array_combine(array_map('ucwords', array_keys($requestHeaders)), array_values($requestHeaders));
        if (isset($requestHeaders['Authorization'])) {
            $headers = trim($requestHeaders['Authorization']);
        }
    }
    return $headers;
}

function getBearerToken() {
    $headers = getAuthorizationHeader();
    if (!empty($headers)) {
        if (preg_match('/Bearer\s(\S+)/', $headers, $matches)) {
            return $matches[1];
        }
    }
    return null;
}
?>