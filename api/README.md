# 软件授权与用户管理系统 API

## 项目概述

这是一个为Access VBA软件提供在线用户管理和授权验证的API系统。通过这个系统，你可以将软件的用户管理、充值、授权验证等功能集中到云服务器上，实现集中化管理。

## 数据库结构

### 用户表 (users)
```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255),
    email VARCHAR(100),
    balance DECIMAL(10,2) DEFAULT 0,
    status TINYINT DEFAULT 1,
    created_at DATETIME,
    last_login DATETIME
);
```

### 授权表 (licenses)
```sql
CREATE TABLE licenses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    software_id VARCHAR(50),
    expire_date DATETIME,
    max_devices INT DEFAULT 1,
    is_active BOOLEAN DEFAULT true
);
```

### 充值记录表 (recharge_records)
```sql
CREATE TABLE recharge_records (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    amount DECIMAL(10,2),
    recharge_time DATETIME,
    payment_method VARCHAR(50)
);
```

## API接口说明

### 认证接口 (auth.php)

#### 用户登录
- **URL**: `/api/auth.php?action=login`
- **方法**: POST
- **参数**:
  ```json
  {
    "username": "用户名",
    "password": "密码"
  }
  ```

#### 用户注册
- **URL**: `/api/auth.php?action=register`
- **方法**: POST
- **参数**:
  ```json
  {
    "username": "用户名",
    "password": "密码",
    "email": "邮箱"
  }
  ```

#### Token验证
- **URL**: `/api/auth.php?action=verify`
- **方法**: POST
- **头部**: `Authorization: Bearer {token}`

### 钱包接口 (wallet.php)

#### 获取余额
- **URL**: `/api/wallet.php?action=balance`
- **方法**: GET
- **头部**: `Authorization: Bearer {token}`

#### 用户充值
- **URL**: `/api/wallet.php?action=recharge`
- **方法**: POST
- **参数**:
  ```json
  {
    "amount": 充值金额,
    "payment_method": "支付方式"
  }
  ```

#### 扣费操作
- **URL**: `/api/wallet.php?action=deduct`
- **方法**: POST
- **参数**:
  ```json
  {
    "amount": 扣费金额,
    "description": "扣费描述"
  }
  ```

### 授权接口 (license.php)

#### 检查授权
- **URL**: `/api/license.php?action=check&software_id={软件ID}`
- **方法**: GET
- **头部**: `Authorization: Bearer {token}`

#### 创建授权
- **URL**: `/api/license.php?action=create`
- **方法**: POST
- **参数**:
  ```json
  {
    "software_id": "软件ID",
    "duration_days": 授权天数,
    "max_devices": 最大设备数
  }
  ```

#### 授权续期
- **URL**: `/api/license.php?action=renew`
- **方法**: POST
- **参数**:
  ```json
  {
    "license_id": 授权ID,
    "duration_days": 续期天数
  }
  ```

## VBA集成代码

### 引用设置
在VBA编辑器中，需要添加以下引用：
- Microsoft XML, v6.0

### 主要函数

#### 用户认证
```vba
' 用户登录
Function UserLogin(username As String, password As String) As APIError

' 用户注册
Function UserRegister(username As String, password As String, email As String) As APIError

' 验证Token
Function VerifyToken() As APIError
```

#### 钱包功能
```vba
' 获取余额
Function GetUserBalance() As Double

' 用户充值
Function UserRecharge(amount As Double, paymentMethod As String) As APIError

' 扣费操作
Function DeductBalance(amount As Double, description As String) As APIError
```

#### 授权管理
```vba
' 检查软件授权
Function CheckLicense(softwareId As String) As Boolean

' 创建新授权
Function CreateLicense(softwareId As String, durationDays As Integer, maxDevices As Integer) As APIError
```

## 部署说明

### 服务器配置
1. 将API文件上传到Web服务器
2. 修改 `config.php` 中的数据库配置：
   ```php
   define('DB_HOST', '你的数据库主机');
   define('DB_USER', '你的数据库用户名');
   define('DB_PASS', '你的数据库密码');
   define('DB_NAME', '你的数据库名');
   define('API_KEY', '你的API密钥');
   ```

3. 确保PHP环境支持PDO和MySQL扩展

### VBA配置
修改 `vba_example.bas` 中的配置：
```vba
Private Const API_BASE_URL As String = "http://你的服务器地址/api/"
Private Const API_KEY As String = "你的API密钥"
```

## 安全说明

1. **API密钥保护**: 确保API密钥安全，不要泄露
2. **HTTPS加密**: 生产环境建议使用HTTPS
3. **输入验证**: API包含输入验证和SQL注入防护
4. **Token过期**: Token默认有效期为1小时
5. **错误处理**: 所有API都包含完善的错误处理

## 使用流程

### 新用户流程
1. 用户注册账号
2. 用户登录系统
3. 用户进行充值
4. 用户购买软件授权
5. 软件验证授权状态

### 软件验证流程
1. 用户启动软件
2. 软件提示用户登录
3. 验证软件授权状态
4. 根据余额判断是否允许使用功能
5. 记录使用日志和扣费

## 扩展建议

1. **添加设备绑定**: 可以扩展授权表支持设备绑定
2. **添加使用日志**: 记录软件功能使用详情
3. **添加支付接口**: 集成第三方支付平台
4. **添加管理后台**: 开发Web管理界面
5. **添加统计功能**: 用户使用统计和分析

## 技术支持

如有问题，请检查：
1. 服务器网络连接
2. 数据库配置是否正确
3. API密钥是否匹配
4. PHP错误日志
5. VBA引用是否正确设置