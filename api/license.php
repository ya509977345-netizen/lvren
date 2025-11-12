<?php
require_once 'config.php';

class LicenseAPI {
    private $db;
    
    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }
    
    // 检查软件授权
    public function checkLicense() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        $softwareId = isset($_GET['software_id']) ? sanitizeInput($_GET['software_id']) : '';
        
        if (empty($softwareId)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '软件ID不能为空']);
            return;
        }
        
        try {
            $stmt = $this->db->prepare("SELECT * FROM licenses WHERE user_id = ? AND software_id = ? AND is_active = 1 AND expire_date > NOW()");
            $stmt->execute([$userId, $softwareId]);
            $license = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($license) {
                echo json_encode([
                    'success' => true,
                    'message' => '授权有效',
                    'license' => [
                        'id' => $license['id'],
                        'expire_date' => $license['expire_date'],
                        'max_devices' => $license['max_devices'],
                        'remaining_days' => $this->calculateRemainingDays($license['expire_date'])
                    ]
                ]);
            } else {
                http_response_code(403);
                echo json_encode([
                    'success' => false,
                    'message' => '授权无效或已过期'
                ]);
            }
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器错误: ' . $e->getMessage()]);
        }
    }
    
    // 获取用户所有授权
    public function getUserLicenses() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        try {
            $stmt = $this->db->prepare("SELECT * FROM licenses WHERE user_id = ? ORDER BY expire_date DESC");
            $stmt->execute([$userId]);
            $licenses = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $formattedLicenses = [];
            foreach ($licenses as $license) {
                $formattedLicenses[] = [
                    'id' => $license['id'],
                    'software_id' => $license['software_id'],
                    'expire_date' => $license['expire_date'],
                    'max_devices' => $license['max_devices'],
                    'is_active' => $license['is_active'],
                    'remaining_days' => $this->calculateRemainingDays($license['expire_date']),
                    'status' => $this->getLicenseStatus($license)
                ];
            }
            
            echo json_encode([
                'success' => true,
                'licenses' => $formattedLicenses,
                'message' => '授权列表获取成功'
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '服务器错误: ' . $e->getMessage()]);
        }
    }
    
    // 创建新授权
    public function createLicense() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        $input = json_decode(file_get_contents('php://input'), true);
        
        $softwareId = isset($input['software_id']) ? sanitizeInput($input['software_id']) : '';
        $durationDays = isset($input['duration_days']) ? intval($input['duration_days']) : 30;
        $maxDevices = isset($input['max_devices']) ? intval($input['max_devices']) : 1;
        
        if (empty($softwareId)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '软件ID不能为空']);
            return;
        }
        
        if ($durationDays <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '授权时长必须大于0']);
            return;
        }
        
        try {
            $expireDate = date('Y-m-d H:i:s', strtotime("+$durationDays days"));
            
            $stmt = $this->db->prepare("INSERT INTO licenses (user_id, software_id, expire_date, max_devices) VALUES (?, ?, ?, ?)");
            $stmt->execute([$userId, $softwareId, $expireDate, $maxDevices]);
            
            $licenseId = $this->db->lastInsertId();
            
            echo json_encode([
                'success' => true,
                'message' => '授权创建成功',
                'license' => [
                    'id' => $licenseId,
                    'software_id' => $softwareId,
                    'expire_date' => $expireDate,
                    'max_devices' => $maxDevices,
                    'remaining_days' => $durationDays
                ]
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '授权创建失败: ' . $e->getMessage()]);
        }
    }
    
    // 续期授权
    public function renewLicense() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        $input = json_decode(file_get_contents('php://input'), true);
        
        $licenseId = isset($input['license_id']) ? intval($input['license_id']) : 0;
        $durationDays = isset($input['duration_days']) ? intval($input['duration_days']) : 30;
        
        if ($licenseId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '授权ID无效']);
            return;
        }
        
        if ($durationDays <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '续期时长必须大于0']);
            return;
        }
        
        try {
            // 检查授权是否存在且属于当前用户
            $checkStmt = $this->db->prepare("SELECT * FROM licenses WHERE id = ? AND user_id = ?");
            $checkStmt->execute([$licenseId, $userId]);
            $license = $checkStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$license) {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => '授权不存在']);
                return;
            }
            
            // 计算新的过期时间
            $currentExpire = new DateTime($license['expire_date']);
            $newExpire = $currentExpire->modify("+$durationDays days")->format('Y-m-d H:i:s');
            
            $updateStmt = $this->db->prepare("UPDATE licenses SET expire_date = ?, is_active = 1 WHERE id = ?");
            $updateStmt->execute([$newExpire, $licenseId]);
            
            echo json_encode([
                'success' => true,
                'message' => '授权续期成功',
                'license' => [
                    'id' => $licenseId,
                    'new_expire_date' => $newExpire,
                    'remaining_days' => $this->calculateRemainingDays($newExpire)
                ]
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '授权续期失败: ' . $e->getMessage()]);
        }
    }
    
    // 禁用授权
    public function disableLicense() {
        $userId = $this->authenticate();
        if (!$userId) return;
        
        $input = json_decode(file_get_contents('php://input'), true);
        $licenseId = isset($input['license_id']) ? intval($input['license_id']) : 0;
        
        if ($licenseId <= 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => '授权ID无效']);
            return;
        }
        
        try {
            // 检查授权是否存在且属于当前用户
            $checkStmt = $this->db->prepare("SELECT * FROM licenses WHERE id = ? AND user_id = ?");
            $checkStmt->execute([$licenseId, $userId]);
            $license = $checkStmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$license) {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => '授权不存在']);
                return;
            }
            
            $updateStmt = $this->db->prepare("UPDATE licenses SET is_active = 0 WHERE id = ?");
            $updateStmt->execute([$licenseId]);
            
            echo json_encode([
                'success' => true,
                'message' => '授权已禁用'
            ]);
            
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => '操作失败: ' . $e->getMessage()]);
        }
    }
    
    // 辅助函数
    private function calculateRemainingDays($expireDate) {
        $expire = new DateTime($expireDate);
        $now = new DateTime();
        $interval = $now->diff($expire);
        return $interval->days;
    }
    
    private function getLicenseStatus($license) {
        $now = new DateTime();
        $expire = new DateTime($license['expire_date']);
        
        if (!$license['is_active']) {
            return 'disabled';
        } elseif ($expire < $now) {
            return 'expired';
        } else {
            return 'active';
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
$license = new LicenseAPI();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $action = isset($_GET['action']) ? sanitizeInput($_GET['action']) : '';
    
    switch ($action) {
        case 'check':
            $license->checkLicense();
            break;
        case 'list':
            $license->getUserLicenses();
            break;
        default:
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => '接口不存在']);
            break;
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = isset($_GET['action']) ? sanitizeInput($_GET['action']) : '';
    
    switch ($action) {
        case 'create':
            $license->createLicense();
            break;
        case 'renew':
            $license->renewLicense();
            break;
        case 'disable':
            $license->disableLicense();
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