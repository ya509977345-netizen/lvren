<?php

require_once 'config.php';
require_once 'rate_limiter.php';

class AuthAPI {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }
    
    // 用户登录
    public function login() {
        // 应用速率限制
        if (!RateLimiter::checkLimit(null, 'auth')) {
            http_response_code(429);
            echo json_encode(['success' => false, 'message' => '请求过于频繁，请稍后再试']);
            return;
        }
        
        // 发送速率限制响应头
        RateLimiter::sendRateLimitHeaders(null, 'auth');
        
        $input = json_decode(file_get_contents('php://input'), true);
        
        // 使用增强输入验证
        $validationRules = [
            'username' => ['required', 'string', 'minLength' => 3, 'maxLength' => 50],
            'password' => ['required', 'string', 'minLength' => 6]
        ];
        
        $validationErrors = validateInput($input, $validationRules);
        if (!empty($validationErrors)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '输入验证失败', 'errors' => $validationErrors]);
            return;
        }
        
        $username = sanitizeInput($input['username']);
        $password = sanitizeInput($input['password']);
        
        try {
            $stmt = $this->db->prepare("SELECT id, username, password_hash, balance, status FROM users WHERE username = ?");
            $stmt->execute([$username]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$user) {
                logApiAccess(0, 'login', "用户名: $username", false);
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => '用户名或密码错误']);
                return;
            }
            
            if (!password_verify($password, $user['password_hash'])) {
                logApiAccess($user['id'], 'login', "用户名: $username, 密码错误", false);
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => '用户名或密码错误']);
                return;
            }
            
            if ($user['status'] != 1) {
                logApiAccess($user['id'], 'login', "用户名: $username, 账户已被禁用", false);
                http_response_code(403);
                echo json_encode(['success' => false, 'message' => '账户已被禁用']);
                return;
            }
            
            // 更新最后登录时间
            $updateStmt = $this->db->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
            $updateStmt->execute([$user['id']]);
            
            // 生成token
            $token = generateToken($user['id']);
            
            logApiAccess($user['id'], 'login', "用户名: $username, 登录成功");
            
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
            logApiAccess(0, 'login', "用户名: $username, 数据库错误", false);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器内部错误，请稍后再试']);
        }
    }
    
    // 用户注册
    public function register() {
        // 应用速率限制
        if (!RateLimiter::checkLimit(null, 'auth')) {
            http_response_code(429);
            echo json_encode(['success' => false, 'message' => '请求过于频繁，请稍后再试']);
            return;
        }
        
        // 发送速率限制响应头
        RateLimiter::sendRateLimitHeaders(null, 'auth');
        
        $input = json_decode(file_get_contents('php://input'), true);
        
        // 使用增强输入验证
        $validationRules = [
            'username' => ['required', 'string', 'minLength' => 3, 'maxLength' => 50],
            'password' => ['required', 'string', 'minLength' => 6, 'maxLength' => 100],
            'email' => ['required', 'email']
        ];
        
        $validationErrors = validateInput($input, $validationRules);
        if (!empty($validationErrors)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '输入验证失败', 'errors' => $validationErrors]);
            return;
        }
        
        $username = sanitizeInput($input['username']);
        $password = sanitizeInput($input['password']);
        $email = sanitizeInput($input['email']);
        
        try {
            // 检查用户名是否已存在
            $checkStmt = $this->db->prepare("SELECT id FROM users WHERE username = ?");
            $checkStmt->execute([$username]);
            if ($checkStmt->fetch()) {
                logApiAccess(0, 'register', "用户名: $username, 用户名已存在", false);
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => '用户名已存在']);
                return;
            }
            
            // 检查邮箱是否已存在
            $checkStmt = $this->db->prepare("SELECT id FROM users WHERE email = ?");
            $checkStmt->execute([$email]);
            if ($checkStmt->fetch()) {
                logApiAccess(0, 'register', "邮箱: $email, 邮箱已被使用", false);
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => '邮箱已被使用']);
                return;
            }
            
            // 创建用户
            $passwordHash = password_hash($password, PASSWORD_DEFAULT);
            $stmt = $this->db->prepare("INSERT INTO users (username, password_hash, email, created_at) VALUES (?, ?, ?, NOW())");
            $stmt->execute([$username, $passwordHash, $email]);
            
            $userId = $this->db->lastInsertId();
            
            logApiAccess($userId, 'register', "用户名: $username, 邮箱: $email");
            
            echo json_encode([
                'success' => true,
                'message' => '注册成功',
                'user_id' => $userId
            ]);
            
        } catch (PDOException $e) {
            logApiAccess(0, 'register', "用户名: $username, 邮箱: $email, 数据库错误", false);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器内部错误，请稍后再试']);
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
            logApiAccess($userId, 'verify_token', "数据库错误", false);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器内部错误，请稍后再试']);
        }
    }
    
    // 修改密码
    public function changePassword() {
        $token = getBearerToken();
        
        if (!$token) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => '请先登录']);
            return;
        }
        
        $userId = verifyToken($token);
        
        if (!$userId) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Token无效或已过期']);
            return;
        }
        
        $input = json_decode(file_get_contents('php://input'), true);
        
        // 使用增强输入验证
        $validationRules = [
            'old_password' => ['required', 'string', 'minLength' => 6],
            'new_password' => ['required', 'string', 'minLength' => 6, 'maxLength' => 100]
        ];
        
        $validationErrors = validateInput($input, $validationRules);
        if (!empty($validationErrors)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '输入验证失败', 'errors' => $validationErrors]);
            return;
        }
        
        $oldPassword = sanitizeInput($input['old_password']);
        $newPassword = sanitizeInput($input['new_password']);
        
        try {
            // 获取用户当前密码
            $stmt = $this->db->prepare("SELECT password_hash FROM users WHERE id = ? AND status = 1");
            $stmt->execute([$userId]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$user) {
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => '用户不存在或已被禁用']);
                return;
            }
            
            // 验证旧密码
            if (!password_verify($oldPassword, $user['password_hash'])) {
                logApiAccess($userId, 'change_password', "旧密码验证失败", false);
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => '旧密码不正确']);
                return;
            }
            
            // 更新密码
            $newPasswordHash = password_hash($newPassword, PASSWORD_DEFAULT);
            $updateStmt = $this->db->prepare("UPDATE users SET password_hash = ?, updated_at = NOW() WHERE id = ?");
            $updateStmt->execute([$newPasswordHash, $userId]);
            
            logApiAccess($userId, 'change_password', "密码修改成功");
            
            echo json_encode([
                'success' => true,
                'message' => '密码修改成功'
            ]);
            
        } catch (PDOException $e) {
            logApiAccess($userId, 'change_password', "数据库错误", false);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器内部错误，请稍后再试']);
        }
    }
    
    // 忘记密码
    public function forgotPassword() {
        // 应用速率限制
        if (!RateLimiter::checkLimit(null, 'password_reset')) {
            http_response_code(429);
            echo json_encode(['success' => false, 'message' => '请求过于频繁，请稍后再试']);
            return;
        }
        
        // 发送速率限制响应头
        RateLimiter::sendRateLimitHeaders(null, 'password_reset');
        
        $input = json_decode(file_get_contents('php://input'), true);
        
        // 使用增强输入验证
        $validationRules = [
            'email' => ['required', 'email']
        ];
        
        $validationErrors = validateInput($input, $validationRules);
        if (!empty($validationErrors)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '输入验证失败', 'errors' => $validationErrors]);
            return;
        }
        
        $email = sanitizeInput($input['email']);
        
        try {
            // 检查邮箱是否存在
            $stmt = $this->db->prepare("SELECT id, username FROM users WHERE email = ? AND status = 1");
            $stmt->execute([$email]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$user) {
                // 为了安全，不透露邮箱是否存在
                logApiAccess(0, 'forgot_password', "邮箱: $email, 不存在", false);
                echo json_encode([
                    'success' => true,
                    'message' => '如果该邮箱已注册，您将收到重置密码的邮件'
                ]);
                return;
            }
            
            // 生成重置令牌
            $resetToken = bin2hex(random_bytes(32));
            $resetExpires = date('Y-m-d H:i:s', time() + 3600); // 1小时后过期
            
            // 更新数据库中的重置令牌
            $updateStmt = $this->db->prepare("UPDATE users SET reset_token = ?, reset_expires = ? WHERE id = ?");
            $updateStmt->execute([$resetToken, $resetExpires, $user['id']]);
            
            // 发送重置密码邮件
            require_once 'email_sender.php';
            $emailSender = new EmailSender();
            $message = $this->getPasswordResetEmailText($user['username'], $resetToken);
            $emailSent = $emailSender->send($email, '密码重置请求', $message);
            
            if ($emailSent) {
                logApiAccess($user['id'], 'forgot_password', "邮箱: $email, 重置邮件已发送");
                
                echo json_encode([
                    'success' => true,
                    'message' => '重置密码链接已发送到您的邮箱，请查收'
                ]);
            } else {
                logApiAccess($user['id'], 'forgot_password', "邮箱: $email, 邮件发送失败", false);
                
                echo json_encode([
                    'success' => false,
                    'message' => '邮件发送失败，请稍后再试或联系管理员'
                ]);
            }
            
        } catch (PDOException $e) {
            logApiAccess(0, 'forgot_password', "邮箱: $email, 数据库错误", false);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器内部错误，请稍后再试']);
        }
    }
    
    // 重置密码
    public function resetPassword() {
        $input = json_decode(file_get_contents('php://input'), true);
        
        // 使用增强输入验证
        $validationRules = [
            'token' => ['required', 'string'],
            'password' => ['required', 'string', 'minLength' => 6, 'maxLength' => 100]
        ];
        
        $validationErrors = validateInput($input, $validationRules);
        if (!empty($validationErrors)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '输入验证失败', 'errors' => $validationErrors]);
            return;
        }
        
        $token = sanitizeInput($input['token']);
        $password = sanitizeInput($input['password']);
        
        try {
            // 验证重置令牌
            $stmt = $this->db->prepare("SELECT id FROM users WHERE reset_token = ? AND reset_expires > NOW() AND status = 1");
            $stmt->execute([$token]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$user) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => '重置令牌无效或已过期']);
                return;
            }
            
            // 更新密码并清除重置令牌
            $passwordHash = password_hash($password, PASSWORD_DEFAULT);
            $updateStmt = $this->db->prepare("UPDATE users SET password_hash = ?, reset_token = NULL, reset_expires = NULL, updated_at = NOW() WHERE id = ?");
            $updateStmt->execute([$passwordHash, $user['id']]);
            
            logApiAccess($user['id'], 'reset_password', "密码重置成功");
            
            echo json_encode([
                'success' => true,
                'message' => '密码重置成功，请使用新密码登录'
            ]);
            
        } catch (PDOException $e) {
            logApiAccess(0, 'reset_password', "令牌: $token, 数据库错误", false);
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器内部错误，请稍后再试']);
        }
    }
    
    // 发送密码重置邮件
    private function sendPasswordResetEmail($email, $username, $resetToken) {
        // 使用PHP mail()函数发送邮件（简化版本）
        try {
            $subject = '密码重置请求';
            $message = $this->getPasswordResetEmailText($username, $resetToken);
            $headers = "From: noreply@lvren.cc

";
            $headers .= "Reply-To: noreply@lvren.cc

";
            $headers .= "Content-Type: text/plain; charset=UTF-8

";
            $headers .= "X-Mailer: PHP/" . phpversion();
            
            // 发送邮件
            $sent = mail($email, $subject, $message, $headers);
            
            if ($sent) {
                error_log("密码重置邮件已发送到: $email");
                return true;
            } else {
                error_log("邮件发送失败到: $email");
                return false;
            }
            
        } catch (Exception $e) {
            error_log("邮件发送异常: " . $e->getMessage());
            return false;
        }
    }
    
    // 备用邮件发送方法（使用PHP mail()函数）
    private function sendPasswordResetEmailFallback($email, $username, $resetToken) {
        $subject = '密码重置请求';
        $message = $this->getPasswordResetEmailText($username, $resetToken);
        $headers = "From: noreply@lvren.cc

";
        $headers .= "Content-Type: text/plain; charset=UTF-8

";
        
        return mail($email, $subject, $message, $headers);
    }
    
    // 获取密码重置邮件HTML模板
    private function getPasswordResetEmailTemplate($username, $resetToken) {
        $resetLink = "https://lvren.cc/reset-password?token=" . $resetToken;
        
        return "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='UTF-8'>
            <title>密码重置</title>
            <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #007cba; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background: #f9f9f9; }
                .button { display: inline-block; padding: 12px 24px; background: #007cba; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }
                .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h2>密码重置请求</h2>
                </div>
                <div class='content'>
                    <p>尊敬的 {$username}，</p>
                    <p>我们收到了您的密码重置请求。如果这不是您本人的操作，请忽略此邮件。</p>
                    <p>点击下面的按钮重置您的密码：</p>
                    <p style='text-align: center;'>
                        <a href='{$resetLink}' class='button'>重置密码</a>
                    </p>
                    <p>或者复制以下链接到浏览器地址栏：</p>
                    <p style='word-break: break-all; background: #eee; padding: 10px;'>{$resetLink}</p>
                    <p><strong>注意：</strong></p>
                    <ul>
                        <li>此链接将在1小时后过期</li>
                        <li>如果您没有请求重置密码，请勿点击此链接</li>
                    </ul>
                </div>
                <div class='footer'>
                    <p>此邮件由系统自动发送，请勿回复。</p>
                    <p>&copy; 2024 软件授权系统. 保留所有权利。</p>
                </div>
            </div>
        </body>
        </html>";
    }
    
    // 获取密码重置邮件纯文本模板
    private function getPasswordResetEmailText($username, $resetToken) {
        $resetLink = "https://lvren.cc/reset-password?token=" . $resetToken;
        
        return "
密码重置请求

尊敬的 {$username}，

我们收到了您的密码重置请求。如果这不是您本人的操作，请忽略此邮件。

点击以下链接重置您的密码：
{$resetLink}

或者复制以下链接到浏览器地址栏：
{$resetLink}

注意：
- 此链接将在1小时后过期
- 如果您没有请求重置密码，请勿点击此链接

此邮件由系统自动发送，请勿回复。

© 2024 软件授权系统. 保留所有权利。
";
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
        case 'change-password':
            $auth->changePassword();
            break;
        case 'forgot-password':
            $auth->forgotPassword();
            break;
        case 'reset-password':
            $auth->resetPassword();
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