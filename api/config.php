<?php

// 数据库配置 - 宝塔面板MySQL配置
define('DB_HOST', 'localhost');
define('DB_USER', 'lvren-user');
define('DB_PASS', 'fDDCN5ryLw2W4fRi');
define('DB_NAME', 'lvren-user');

// API配置 - 设置一个安全的API密钥
define('API_KEY', 'Wang869678');
define('TOKEN_EXPIRE', 3600); // 1小时

// 错误报告设置
error_reporting(0);
ini_set('display_errors', 0);

// CORS设置 - 限制允许的来源域名
$allowedOrigins = [
    'https://lvren.cc',
    'http://lvren.cc',
    'https://www.lvren.cc',
    'http://www.lvren.cc',
    'http://localhost:3000',
    'http://localhost:3001',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:3001'
];

$origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '';
if (in_array($origin, $allowedOrigins)) {
    header('Access-Control-Allow-Origin: ' . $origin);
} else {
    // 开发环境可以临时使用通配符，生产环境应严格限制
    header('Access-Control-Allow-Origin: https://lvren.cc');
}

header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Credentials: true');

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
// 简单JWT实现
class SimpleJWT {
    private static $secretKey = 'lvren_cc_api_secret_key_2024'; // 实际项目中应使用环境变量
    
    public static function encode($payload, $expiry = 3600) {
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        $payload['exp'] = time() + $expiry;
        $payload['iat'] = time();
        $payload = json_encode($payload);
        
        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
        
        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, self::$secretKey, true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
        
        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }
    
    public static function decode($jwt) {
        $parts = explode('.', $jwt);
        if (count($parts) != 3) {
            return false;
        }
        
        $base64UrlHeader = $parts[0];
        $base64UrlPayload = $parts[1];
        $base64UrlSignature = $parts[2];
        
        $payload = base64_decode(str_replace(['-', '_'], ['+', '/'], $base64UrlPayload));
        $payloadArray = json_decode($payload, true);
        if (!$payloadArray) {
            return false;
        }
        
        // 检查过期时间
        if (isset($payloadArray['exp']) && $payloadArray['exp'] < time()) {
            return false;
        }
        
        // 验证签名
        $newSignature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, self::$secretKey, true);
        $base64UrlNewSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($newSignature));
        
        if ($base64UrlSignature !== $base64UrlNewSignature) {
            return false;
        }
        
        return $payloadArray;
    }
}

// 生成Token函数
function generateToken($user_id) {
    return SimpleJWT::encode(['user_id' => $user_id], TOKEN_EXPIRE);
}

// 验证Token函数
function verifyToken($token) {
    try {
        $payload = SimpleJWT::decode($token);
        if (!$payload) {
            return false;
        }
        return $payload['user_id'];
    } catch (Exception $e) {
        // Token验证失败
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

// API日志记录功能
function logApiAccess($userId, $action, $description = '', $success = true) {
    try {
        $database = new Database();
        $db = $database->getConnection();
        
        $ipAddress = $_SERVER['REMOTE_ADDR'] ?? '';
        $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';
        
        $stmt = $db->prepare("INSERT INTO system_logs (user_id, action, description, ip_address, user_agent) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([$userId, $action, $description . ($success ? '' : ' [FAILED]'), $ipAddress, $userAgent]);
    } catch (Exception $e) {
        // 日志记录失败不应影响API响应
        error_log("日志记录失败: " . $e->getMessage());
    }
}

// 输入验证增强函数
function validateInput($input, $rules) {
    $errors = [];
    
    foreach ($rules as $field => $fieldRules) {
        if (!isset($input[$field])) {
            if (in_array('required', $fieldRules)) {
                $errors[$field] = '字段 ' . $field . ' 是必需的';
            }
            continue;
        }
        
        $value = $input[$field];
        
        // 检查字符串长度
        if (in_array('string', $fieldRules) && is_string($value)) {
            if (isset($fieldRules['minLength']) && strlen($value) < $fieldRules['minLength']) {
                $errors[$field] = '字段 ' . $field . ' 长度不能少于 ' . $fieldRules['minLength'] . ' 个字符';
            }
            if (isset($fieldRules['maxLength']) && strlen($value) > $fieldRules['maxLength']) {
                $errors[$field] = '字段 ' . $field . ' 长度不能超过 ' . $fieldRules['maxLength'] . ' 个字符';
            }
        }
        
        // 检查数字范围
        if (in_array('number', $fieldRules) && is_numeric($value)) {
            if (isset($fieldRules['min']) && $value < $fieldRules['min']) {
                $errors[$field] = '字段 ' . $field . ' 不能小于 ' . $fieldRules['min'];
            }
            if (isset($fieldRules['max']) && $value > $fieldRules['max']) {
                $errors[$field] = '字段 ' . $field . ' 不能大于 ' . $fieldRules['max'];
            }
        }
        
        // 邮箱验证
        if (in_array('email', $fieldRules) && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
            $errors[$field] = '字段 ' . $field . ' 必须是有效的邮箱地址';
        }
    }
    
    return $errors;
}
?>