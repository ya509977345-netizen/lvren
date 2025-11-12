<?php
require_once 'config.php';

class WalletAPI {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }
    
    // 获取用户余额
    public function getBalance() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        try {
            $stmt = $this->db->prepare("SELECT balance FROM users WHERE id = ?");
            $stmt->execute([$userId]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            echo json_encode([
                'success' => true,
                'balance' => $result['balance'],
                'message' => '余额查询成功'
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器错误: ' . $e->getMessage()]);
        }
    }
    
    // 充值记录
    public function rechargeRecord() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        $input = json_decode(file_get_contents('php://input'), true);
        $amount = isset($input['amount']) ? floatval($input['amount']) : 0;
        $paymentMethod = isset($input['payment_method']) ? sanitizeInput($input['payment_method']) : 'unknown';
        
        if ($amount <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '充值金额必须大于0']);
            return;
        }
        
        try {
            // 开始事务
            $this->db->beginTransaction();
            
            // 记录充值
            $stmt = $this->db->prepare("INSERT INTO recharge_records (user_id, amount, recharge_time, payment_method) VALUES (?, ?, NOW(), ?)");
            $stmt->execute([$userId, $amount, $paymentMethod]);
            
            // 更新用户余额
            $updateStmt = $this->db->prepare("UPDATE users SET balance = balance + ? WHERE id = ?");
            $updateStmt->execute([$amount, $userId]);
            
            $this->db->commit();
            
            // 获取更新后的余额
            $balanceStmt = $this->db->prepare("SELECT balance FROM users WHERE id = ?");
            $balanceStmt->execute([$userId]);
            $balance = $balanceStmt->fetch(PDO::FETCH_ASSOC)['balance'];
            
            echo json_encode([
                'success' => true,
                'message' => '充值成功',
                'recharge_amount' => $amount,
                'new_balance' => $balance
            ]);
            
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '充值失败: ' . $e->getMessage()]);
        }
    }
    
    // 获取充值历史
    public function getRechargeHistory() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
        $offset = isset($_GET['offset']) ? intval($_GET['offset']) : 0;
        
        try {
            $stmt = $this->db->prepare("SELECT amount, payment_method, recharge_time FROM recharge_records WHERE user_id = ? ORDER BY recharge_time DESC LIMIT ? OFFSET ?");
            $stmt->execute([$userId, $limit, $offset]);
            $records = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // 获取总记录数
            $countStmt = $this->db->prepare("SELECT COUNT(*) as total FROM recharge_records WHERE user_id = ?");
            $countStmt->execute([$userId]);
            $total = $countStmt->fetch(PDO::FETCH_ASSOC)['total'];
            
            echo json_encode([
                'success' => true,
                'records' => $records,
                'total' => $total,
                'message' => '充值记录查询成功'
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器错误: ' . $e->getMessage()]);
        }
    }
    
    // 扣费操作（用于软件功能使用）
    public function deductBalance() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        $input = json_decode(file_get_contents('php://input'), true);
        $amount = isset($input['amount']) ? floatval($input['amount']) : 0;
        $description = isset($input['description']) ? sanitizeInput($input['description']) : '软件功能使用';
        
        if ($amount <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '扣费金额必须大于0']);
            return;
        }
        
        try {
            // 检查余额是否足够
            $stmt = $this->db->prepare("SELECT balance FROM users WHERE id = ?");
            $stmt->execute([$userId]);
            $balance = $stmt->fetch(PDO::FETCH_ASSOC)['balance'];
            
            if ($balance < $amount) {
                http_response_code(400);
                echo json_encode([
                    'success' => false, 
                    'message' => '余额不足',
                    'current_balance' => $balance,
                    'required_amount' => $amount
                ]);
                return;
            }
            
            // 开始事务
            $this->db->beginTransaction();
            
            // 扣费
            $updateStmt = $this->db->prepare("UPDATE users SET balance = balance - ? WHERE id = ?");
            $updateStmt->execute([$amount, $userId]);
            
            // 记录扣费（可以扩展为消费记录表）
            $recordStmt = $this->db->prepare("INSERT INTO recharge_records (user_id, amount, recharge_time, payment_method) VALUES (?, ?, NOW(), ?)");
            $recordStmt->execute([$userId, -$amount, $description]);
            
            $this->db->commit();
            
            // 获取更新后的余额
            $balanceStmt = $this->db->prepare("SELECT balance FROM users WHERE id = ?");
            $balanceStmt->execute([$userId]);
            $newBalance = $balanceStmt->fetch(PDO::FETCH_ASSOC)['balance'];
            
            echo json_encode([
                'success' => true,
                'message' => '扣费成功',
                'deducted_amount' => $amount,
                'new_balance' => $newBalance,
                'description' => $description
            ]);
            
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '扣费失败: ' . $e->getMessage()]);
        }
    }
    
    // 认证函数
    private function authenticate() {
        $token = getBearerToken();
        
        if (!$token) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Token不存在']);
            return false;
        }
        
        $userId = verifyToken($token);
        
        if (!$userId) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Token无效或已过期']);
            return false;
        }
        
        return $userId;
    }
}

// 路由处理
$wallet = new WalletAPI();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $action = isset($_GET['action']) ? sanitizeInput($_GET['action']) : '';
    
    switch ($action) {
        case 'balance':
            $wallet->getBalance();
            break;
        case 'recharge_history':
            $wallet->getRechargeHistory();
            break;
        default:
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => '接口不存在']);
            break;
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = isset($_GET['action']) ? sanitizeInput($_GET['action']) : '';
    
    switch ($action) {
        case 'recharge':
            $wallet->rechargeRecord();
            break;
        case 'deduct':
            $wallet->deductBalance();
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