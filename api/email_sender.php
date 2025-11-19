<?php
/**
 * 邮件发送类
 * 支持多种邮件发送方式，无需本地邮件服务
 */

class EmailSender {
    private $config;
    
    public function __construct() {
        $this->config = [
            'from' => 'noreply@lvren.cc',
            'from_name' => '软件授权系统',
            'reply_to' => 'support@lvren.cc'
        ];
    }
    
    /**
     * 发送邮件
     */
    public function send($to, $subject, $message, $isHtml = false) {
        // 优先级1: 尝试使用第三方API（推荐）
        if ($result = $this->sendViaThirdPartyAPI($to, $subject, $message, $isHtml)) {
            return $result;
        }
        
        // 优先级2: 尝试使用系统mail()函数
        if ($result = $this->sendViaMailFunction($to, $subject, $message, $isHtml)) {
            return $result;
        }
        
        // 优先级3: 保存到文件（备用方案）
        return $this->saveToFile($to, $subject, $message);
    }
    
    /**
     * 使用第三方邮件API发送
     */
    private function sendViaThirdPartyAPI($to, $subject, $message, $isHtml) {
        // 使用免费的邮件发送服务
        $services = [
            $this->getMailgunConfig(),
            $this->getSendGridConfig(),
            $this->getBrevoConfig()
        ];
        
        foreach ($services as $service) {
            if ($service['enabled']) {
                $result = $this->sendViaAPI($service, $to, $subject, $message, $isHtml);
                if ($result) {
                    error_log("邮件已通过 {$service['name']} 发送到: $to");
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * 使用Mailgun发送邮件
     */
    private function getMailgunConfig() {
        return [
            'enabled' => false, // 设为true以启用
            'name' => 'Mailgun',
            'url' => 'https://api.mailgun.net/v3/YOUR_DOMAIN/messages',
            'api_key' => 'YOUR_MAILGUN_API_KEY', // 替换为实际密钥
            'from' => 'Software License <noreply@YOUR_DOMAIN>'
        ];
    }
    
    /**
     * 使用SendGrid发送邮件
     */
    private function getSendGridConfig() {
        return [
            'enabled' => false, // 设为true以启用
            'name' => 'SendGrid',
            'url' => 'https://api.sendgrid.com/v3/mail/send',
            'api_key' => 'YOUR_SENDGRID_API_KEY', // 替换为实际密钥
            'from' => 'noreply@lvren.cc'
        ];
    }
    
    /**
     * 使用Brevo发送邮件
     */
    private function getBrevoConfig() {
        return [
            'enabled' => false, // 设为true以启用
            'name' => 'Brevo (Sendinblue)',
            'url' => 'https://api.sendinblue.com/v3/smtp/email',
            'api_key' => 'YOUR_BREVO_API_KEY', // 替换为实际密钥
            'from' => 'noreply@lvren.cc'
        ];
    }
    
    /**
     * 通用API发送方法
     */
    private function sendViaAPI($service, $to, $subject, $message, $isHtml) {
        try {
            $ch = curl_init($service['url']);
            curl_setopt($ch, CURLOPT_POST, true);
            
            $data = $this->prepareAPIData($service, $to, $subject, $message, $isHtml);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Authorization: Bearer ' . $service['api_key'],
                'Content-Type: application/json'
            ]);
            
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            return $httpCode >= 200 && $httpCode < 300;
            
        } catch (Exception $e) {
            error_log("API发送邮件失败: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * 准备API数据
     */
    private function prepareAPIData($service, $to, $subject, $message, $isHtml) {
        switch ($service['name']) {
            case 'SendGrid':
                return [
                    'personalizations' => [[
                        'to' => [['email' => $to]],
                        'subject' => $subject
                    ]],
                    'from' => ['email' => $service['from']],
                    'content' => [[
                        'type' => $isHtml ? 'text/html' : 'text/plain',
                        'value' => $message
                    ]]
                ];
                
            case 'Mailgun':
                return [
                    'from' => $service['from'],
                    'to' => $to,
                    'subject' => $subject,
                    'text' => $isHtml ? strip_tags($message) : $message,
                    'html' => $isHtml ? $message : null
                ];
                
            case 'Brevo':
                return [
                    'sender' => ['email' => $service['from']],
                    'to' => [['email' => $to]],
                    'subject' => $subject,
                    'htmlContent' => $isHtml ? $message : null,
                    'textContent' => $isHtml ? strip_tags($message) : $message
                ];
                
            default:
                return [];
        }
    }
    
    /**
     * 使用PHP mail()函数发送
     */
    private function sendViaMailFunction($to, $subject, $message, $isHtml) {
        if (!function_exists('mail')) {
            return false;
        }
        
        $headers = "From: {$this->config['from']}\r\n";
        $headers .= "Reply-To: {$this->config['reply_to']}\r\n";
        
        if ($isHtml) {
            $headers .= "MIME-Version: 1.0\r\n";
            $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
        } else {
            $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
        }
        
        $headers .= "X-Mailer: PHP/" . phpversion();
        
        try {
            $result = mail($to, $subject, $message, $headers);
            if ($result) {
                error_log("邮件已通过 mail() 发送到: $to");
            }
            return $result;
        } catch (Exception $e) {
            error_log("mail() 发送失败: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * 保存邮件到文件（备用方案）
     */
    private function saveToFile($to, $subject, $message) {
        try {
            $dir = __DIR__ . '/email_queue';
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }
            
            $filename = $dir . '/' . date('Y-m-d_H-i-s') . '_' . uniqid() . '.eml';
            $content = "To: $to\r\n";
            $content .= "Subject: $subject\r\n";
            $content .= "Date: " . date('r') . "\r\n";
            $content .= "From: {$this->config['from']}\r\n\r\n";
            $content .= $message;
            
            $result = file_put_contents($filename, $content);
            if ($result) {
                error_log("邮件已保存到文件: $filename");
                return true;
            }
            return false;
            
        } catch (Exception $e) {
            error_log("保存邮件文件失败: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * 获取邮件发送状态
     */
    public function getStatus() {
        $status = [
            'available' => false,
            'method' => 'none',
            'message' => '邮件发送服务不可用',
            'recommendations' => []
        ];
        
        // 检查第三方API配置
        $apis = [
            $this->getMailgunConfig(),
            $this->getSendGridConfig(),
            $this->getBrevoConfig()
        ];
        
        $configuredAPIs = array_filter($apis, function($api) {
            return $api['enabled'] && !empty($api['api_key']) && $api['api_key'] !== 'YOUR_' . strtoupper($api['name']) . '_API_KEY';
        });
        
        if (!empty($configuredAPIs)) {
            $status['available'] = true;
            $status['method'] = '第三方API';
            $status['message'] = '使用第三方邮件服务发送邮件';
            $status['configured'] = array_map(function($api) { return $api['name']; }, $configuredAPIs);
        }
        
        // 检查mail()函数
        if (!$status['available'] && function_exists('mail')) {
            $status['available'] = true;
            $status['method'] = 'PHP mail()';
            $status['message'] = '使用PHP mail()函数发送邮件';
            $status['recommendations'][] = '建议安装系统邮件服务以提高可靠性';
        }
        
        // 检查文件保存
        if (!$status['available']) {
            $status['method'] = '文件备份';
            $status['message'] = '邮件将保存到文件，需要手动处理';
            $status['recommendations'][] = '建议配置第三方邮件服务或安装系统邮件服务';
        }
        
        return $status;
    }
}
?>