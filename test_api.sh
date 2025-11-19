#!/bin/bash

# 乐人软件API测试脚本
# 使用curl命令测试所有API接口

BASE_URL="https://lvren.cc/api"

echo "乐人软件API测试开始"
echo "测试时间: $(date)"
echo "基础URL: $BASE_URL"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_endpoint() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="$4"
    local headers="$5"
    
    echo -e "${YELLOW}测试: $name${NC}"
    echo "URL: $url"
    echo "方法: $method"
    
    # 构建curl命令
    local cmd="curl -s -X $method"
    
    if [ ! -z "$data" ]; then
        cmd="$cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    if [ ! -z "$headers" ]; then
        cmd="$cmd -H '$headers'"
    fi
    
    cmd="$cmd '$url'"
    
    # 执行命令并获取响应
    local response=$(eval $cmd)
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" -X $method "$url")
    
    # 检查状态码
    if [ "$status_code" -eq 200 ]; then
        echo -e "${GREEN}✓ 状态码: $status_code${NC}"
        echo "响应: $response"
    else
        echo -e "${RED}✗ 状态码: $status_code${NC}"
        echo "响应: $response"
    fi
    
    echo ""
}

# 1. 测试数据库连接
test_endpoint "数据库连接" "$BASE_URL/config.php" "GET"

# 2. 创建测试用户数据
TEST_USERNAME="testuser_$(date +%s)"
TEST_PASSWORD="test123456"
TEST_EMAIL="test_$(date +%s)@example.com"

REGISTER_DATA="{\"username\":\"$TEST_USERNAME\",\"password\":\"$TEST_PASSWORD\",\"email\":\"$TEST_EMAIL\"}"

# 3. 测试用户注册
test_endpoint "用户注册" "$BASE_URL/auth.php?action=register" "POST" "$REGISTER_DATA"

# 4. 测试用户登录
LOGIN_DATA="{\"username\":\"$TEST_USERNAME\",\"password\":\"$TEST_PASSWORD\"}"
test_endpoint "用户登录" "$BASE_URL/auth.php?action=login" "POST" "$LOGIN_DATA"

# 从登录响应中提取token（假设响应格式正确）
LOGIN_RESPONSE=$(curl -s -X POST -H 'Content-Type: application/json' -d "$LOGIN_DATA" "$BASE_URL/auth.php?action=login")
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ ! -z "$TOKEN" ]; then
    echo -e "${GREEN}✓ 获取到Token: ${TOKEN:0:20}...${NC}"
    echo ""
    
    # 5. 测试Token验证
    test_endpoint "Token验证" "$BASE_URL/auth.php?action=verify" "POST" "" "Authorization: Bearer $TOKEN"
    
    # 6. 测试余额查询
    test_endpoint "余额查询" "$BASE_URL/wallet.php?action=balance" "GET" "" "Authorization: Bearer $TOKEN"
    
    # 7. 测试充值
    RECHARGE_DATA='{"amount":100.0,"payment_method":"test"}'
    test_endpoint "充值" "$BASE_URL/wallet.php?action=recharge" "POST" "$RECHARGE_DATA" "Authorization: Bearer $TOKEN"
    
    # 8. 测试授权检查
    test_endpoint "授权检查" "$BASE_URL/license.php?action=check&software_id=test_app" "GET" "" "Authorization: Bearer $TOKEN"
    
    # 9. 测试创建授权
    LICENSE_DATA='{"software_id":"test_app","duration_days":30,"max_devices":3}'
    test_endpoint "创建授权" "$BASE_URL/license.php?action=create" "POST" "$LICENSE_DATA" "Authorization: Bearer $TOKEN"
    
else
    echo -e "${RED}✗ 无法获取Token，跳过后续测试${NC}"
fi

# 10. 测试错误情况
echo -e "${YELLOW}错误处理测试:${NC}"

# 空数据测试
test_endpoint "空数据登录" "$BASE_URL/auth.php?action=login" "POST" '{}'

# 错误密码测试
WRONG_LOGIN='{"username":"nonexistent","password":"wrongpassword"}'
test_endpoint "错误凭证登录" "$BASE_URL/auth.php?action=login" "POST" "$WRONG_LOGIN"

# 无效接口测试
test_endpoint "无效接口" "$BASE_URL/auth.php?action=nonexistent" "GET"

# 错误的HTTP方法测试
test_endpoint "错误方法" "$BASE_URL/auth.php?action=login" "GET"

# 无效Token测试
test_endpoint "无效Token" "$BASE_URL/wallet.php?action=balance" "GET" "" "Authorization: Bearer invalid_token_123"

echo -e "${GREEN}测试完成${NC}"
echo "测试用户信息:"
echo "  用户名: $TEST_USERNAME"
echo "  密码: $TEST_PASSWORD"
echo "  邮箱: $TEST_EMAIL"

if [ ! -z "$TOKEN" ]; then
    echo "  获取到Token: ${TOKEN:0:20}..."
fi