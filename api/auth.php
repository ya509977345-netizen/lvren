<?php
require_once 'config.php';

class AuthAPI {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }
    
    // 用户登录
    public function login() {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($input['username']) || !isset($input['password'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '用户名和密码不能为空']);
            return;
        }
        
        $username = sanitizeInput($input['username']);
        $password = sanitizeInput($input['password']);
        
        try {
            $stmt = $this->db->prepare("SELECT id, username, password_hash, balance, status FROM users WHERE username = ?");
            $stmt->execute([$username]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$user) {
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => '用户名不存在']);
                return;
            }
            
            if (!password_verify($password, $user['password_hash'])) {
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => '密码错误']);
                return;
            }
            
            if ($user['status'] != 1) {
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => '账户已被禁用']);
                return;
            }
            
            // 更新最后登录时间
            $updateStmt = $this->db->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
            $updateStmt->execute([$user['id']]);
            
            // 生成token
            $token = generateToken($user['id']);
            
            echo json_encode([
                'success' => true,
                'message' => '登录成功',
                'token' => $token,
                'user' => [
                    'id' => $user['id'],
                    'username' => $user['username'],
                    'balance' => $user['balance']
                ]
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器错误: ' . $e->getMessage()]);
        }
    }
    
    // 用户注册
    public function register() {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($input['username']) || !isset($input['password']) || !isset($input['email'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '请填写完整信息']);
            return;
        }
        
        $username = sanitizeInput($input['username']);
        $password = sanitizeInput($input['password']);
        $email = sanitizeInput($input['email']);
        
        // 验证用户名长度
        if (strlen($username) < 3 || strlen($username) > 50) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '用户名长度必须在3-50个字符之间']);
            return;
        }
        
        // 验证邮箱格式
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '邮箱格式不正确']);
            return;
        }
        
        try {
            // 检查用户名是否已存在
            $checkStmt = $this->db->prepare("SELECT id FROM users WHERE username = ?");
            $checkStmt->execute([$username]);
            if ($checkStmt->fetch()) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => '用户名已存在']);
                return;
            }
            
            // 检查邮箱是否已存在
            $checkStmt = $this->db->prepare("SELECT id FROM users WHERE email = ?");
            $checkStmt->execute([$email]);
            if ($checkStmt->fetch()) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => '邮箱已被使用']);
                return;
            }
            
            // 创建用户
            $passwordHash = password_hash($password, PASSWORD_DEFAULT);
            $stmt = $this->db->prepare("INSERT INTO users (username, password_hash, email, created_at) VALUES (?, ?, ?, NOW())");
            $stmt->execute([$username, $passwordHash, $email]);
            
            $userId = $this->db->lastInsertId();
            
            echo json_encode([
                'success' => true,
                'message' => '注册成功',
                'user_id' => $userId
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器错误: ' . $e->getMessage()]);
        }
    }
    
    // 验证token
    public function verifyToken() {
        $token = getBearerToken();
        
        if (!$token) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Token不存在']);
            return;
        }
        
        $userId = verifyToken($token);
        
        if (!$userId) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Token无效或已过期']);
            return;
        }
        
        try {
            $stmt = $this->db->prepare("SELECT id, username, balance FROM users WHERE id = ? AND status = 1");
            $stmt->execute([$userId]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$user) {
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => '用户不存在或已被禁用']);
                return;
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'Token验证成功',
                'user' => $user
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器错误: ' . $e->getMessage()]);
        }
    }
}

// 路由处理
$auth = new AuthAPI();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = isset($_GET['action']) ? sanitizeInput($_GET['action']) : '';
    
    switch ($action) {
        case 'login':
            $auth->login();
            break;
        case 'register':
            $auth->register();
            break;
        case 'verify':
            $auth->verifyToken();
            break;
        default:
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => '接口不存在']);
            break;
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => '方法不允许']);
}
?>