<?php
/**
 * API速率限制中间件
 * 基于IP地址和用户ID的简单速率限制实现
 */

class RateLimiter {
    private static $limits = [
        'default' => ['requests' => 60, 'window' => 60], // 每分钟60次请求
        'auth' => ['requests' => 5, 'window' => 60], // 登录/注册每分钟5次请求
        'wallet' => ['requests' => 30, 'window' => 60], // 钱包操作每分钟30次请求
        'license' => ['requests' => 20, 'window' => 60] // 授权操作每分钟20次请求
    ];
    
    /**
     * 检查请求是否超过速率限制
     * @param string $userId 用户ID，可为空
     * @param string $category API类别 (default, auth, wallet, license)
     * @return bool 是否允许请求
     */
    public static function checkLimit($userId = null, $category = 'default') {
        // 确定使用哪个限制规则
        $limitRule = self::$limits[$category] ?? self::$limits['default'];
        
        // 使用IP地址作为基本标识符
        $ipAddress = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
        
        // 如果有用户ID，使用用户ID+IP的组合键
        $key = $userId ? "user:$userId" : "ip:$ipAddress";
        $key = "rate_limit:$category:$key";
        
        try {
            $database = new Database();
            $db = $database->getConnection();
            
            // 清理过期的速率限制记录
            self::cleanupExpiredRecords($db);
            
            // 检查当前窗口内的请求数
            $stmt = $db->prepare("SELECT COUNT(*) as request_count FROM rate_limits WHERE `key` = ? AND created_at > ?");
            $stmt->execute([$key, date('Y-m-d H:i:s', time() - $limitRule['window'])]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $currentCount = $result['request_count'];
            
            if ($currentCount >= $limitRule['requests']) {
                return false; // 超过限制
            }
            
            // 记录本次请求
            $insertStmt = $db->prepare("INSERT INTO rate_limits (`key`, created_at) VALUES (?, NOW())");
            $insertStmt->execute([$key]);
            
            return true; // 允许请求
            
        } catch (Exception $e) {
            // 如果速率限制系统出错，默认允许请求以避免影响正常服务
            error_log("速率限制检查失败: " . $e->getMessage());
            return true;
        }
    }
    
    /**
     * 发送速率限制响应头
     */
    public static function sendRateLimitHeaders($userId = null, $category = 'default') {
        $limitRule = self::$limits[$category] ?? self::$limits['default'];
        $ipAddress = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
        $key = $userId ? "user:$userId" : "ip:$ipAddress";
        $key = "rate_limit:$category:$key";
        
        try {
            $database = new Database();
            $db = $database->getConnection();
            
            $stmt = $db->prepare("SELECT COUNT(*) as request_count FROM rate_limits WHERE `key` = ? AND created_at > ?");
            $stmt->execute([$key, date('Y-m-d H:i:s', time() - $limitRule['window'])]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            $remaining = max(0, $limitRule['requests'] - $result['request_count']);
            $reset = time() + $limitRule['window'];
            
            header("X-RateLimit-Limit: {$limitRule['requests']}");
            header("X-RateLimit-Remaining: $remaining");
            header("X-RateLimit-Reset: $reset");
            
        } catch (Exception $e) {
            // 忽略错误，不影响API响应
            error_log("速率限制头信息生成失败: " . $e->getMessage());
        }
    }
    
    /**
     * 清理过期的速率限制记录
     */
    private static function cleanupExpiredRecords($db) {
        // 每分钟随机清理一次，使用低概率避免性能影响
        if (rand(1, 100) <= 5) {
            $stmt = $db->prepare("DELETE FROM rate_limits WHERE created_at < ?");
            $stmt->execute([date('Y-m-d H:i:s', time() - 300)]); // 删除5分钟前的记录
        }
    }
}

// 创建速率限制表（如果不存在）
$createRateLimitTable = "
CREATE TABLE IF NOT EXISTS rate_limits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    `key` VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_key (`key`),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
";

try {
    $database = new Database();
    $db = $database->getConnection();
    $db->exec($createRateLimitTable);
} catch (Exception $e) {
    error_log("创建速率限制表失败: " . $e->getMessage());
}
?>