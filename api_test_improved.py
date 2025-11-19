#!/usr/bin/env python3
"""
改进后的API测试脚本
专门测试新增的安全性和功能改进
"""

import requests
import json
import time
from datetime import datetime

# 基础配置
BASE_URL = "https://lvren.cc/api"
test_users = []

def print_response(title, response):
    """格式化打印响应结果"""
    print(f"\n{'='*60}")
    print(f"{title}")
    print(f"{'='*60}")
    print(f"URL: {response.url}")
    print(f"状态码: {response.status_code}")
    
    # 检查速率限制头
    rate_limit_headers = {
        'X-RateLimit-Limit': response.headers.get('X-RateLimit-Limit'),
        'X-RateLimit-Remaining': response.headers.get('X-RateLimit-Remaining'),
        'X-RateLimit-Reset': response.headers.get('X-RateLimit-Reset')
    }
    
    if any(rate_limit_headers.values()):
        print("速率限制信息:")
        for key, value in rate_limit_headers.items():
            if value:
                print(f"  {key}: {value}")
    
    if response.status_code == 200:
        try:
            data = response.json()
            print(f"响应数据: {json.dumps(data, indent=2, ensure_ascii=False)}")
        except:
            print(f"响应内容: {response.text}")
    else:
        print(f"错误信息: {response.text}")
    return response.json() if response.status_code == 200 else None

def test_jwt_token():
    """测试JWT Token功能"""
    print("\n{'='*60}")
    print("测试JWT Token功能")
    print(f"{'='*60}")
    
    # 用户注册
    register_data = {
        "username": f"jwt_test_{int(time.time())}",
        "password": "test123456",
        "email": f"jwt_test_{int(time.time())}@example.com"
    }
    
    response = requests.post(f"{BASE_URL}/auth.php?action=register", 
                            json=register_data)
    result = print_response("用户注册测试", response)
    
    if result and result.get('success'):
        # 用户登录获取Token
        login_data = {
            "username": register_data['username'],
            "password": register_data['password']
        }
        
        response = requests.post(f"{BASE_URL}/auth.php?action=login", 
                                json=login_data)
        result = print_response("用户登录测试", response)
        
        if result and result.get('success'):
            token = result.get('token')
            print(f"\n获取到的Token: {token[:30]}...")
            
            # 检查Token结构（JWT应该有3个部分，由点分隔）
            parts = token.split('.')
            if len(parts) == 3:
                print("✅ Token格式正确 - 符合JWT标准（3个部分）")
                try:
                    # 尝试解码Header部分
                    import base64
                    header = json.loads(base64.b64decode(parts[0] + '==').decode())
                    payload = json.loads(base64.b64decode(parts[1] + '==').decode())
                    
                    print(f"✅ Token Header: {header}")
                    print(f"✅ Token Payload (部分): user_id={payload.get('user_id')}, exp={payload.get('exp')}")
                    
                    # 验证Token
                    headers = {'Authorization': f'Bearer {token}'}
                    response = requests.post(f"{BASE_URL}/auth.php?action=verify", 
                                           headers=headers)
                    result = print_response("Token验证测试", response)
                    
                    if result and result.get('success'):
                        print("✅ JWT Token验证成功")
                    else:
                        print("❌ JWT Token验证失败")
                        
                except Exception as e:
                    print(f"❌ Token解析错误: {e}")
            else:
                print(f"❌ Token格式不正确，应该有3个部分，实际有{len(parts)}个部分")
                
            # 测试无效Token
            invalid_token = "invalid.jwt.token"
            headers = {'Authorization': f'Bearer {invalid_token}'}
            response = requests.post(f"{BASE_URL}/auth.php?action=verify", 
                                   headers=headers)
            print_response("无效Token测试", response)

def test_rate_limiting():
    """测试速率限制功能"""
    print(f"\n{'='*60}")
    print("测试速率限制功能")
    print(f"{'='*60}")
    
    # 先注册并登录一个用户
    register_data = {
        "username": f"rate_test_{int(time.time())}",
        "password": "test123456",
        "email": f"rate_test_{int(time.time())}@example.com"
    }
    
    response = requests.post(f"{BASE_URL}/auth.php?action=register", 
                            json=register_data)
    
    # 用户登录
    login_data = {
        "username": register_data['username'],
        "password": register_data['password']
    }
    
    response = requests.post(f"{BASE_URL}/auth.php?action=login", 
                            json=login_data)
    result = response.json()
    
    if result and result.get('success'):
        token = result.get('token')
        headers = {'Authorization': f'Bearer {token}'}
        
        print("开始频繁请求测试速率限制...")
        
        # 快速发送多个请求测试速率限制
        success_count = 0
        rate_limited = False
        for i in range(10):  # 发送10个快速请求
            response = requests.get(f"{BASE_URL}/wallet.php?action=balance", 
                                   headers=headers)
            
            if response.status_code == 200:
                success_count += 1
                print(f"请求 {i+1}: 成功 (200)")
            elif response.status_code == 429:
                rate_limited = True
                print(f"请求 {i+1}: 被速率限制 (429)")
                break
            else:
                print(f"请求 {i+1}: 其他错误 ({response.status_code})")
        
        if rate_limited:
            print("✅ 速率限制功能正常工作")
        else:
            print("⚠️ 速率限制未触发，可能需要更多请求或调整限制阈值")
        
        # 等待一段时间后再次尝试
        print("\n等待5秒后再次尝试...")
        time.sleep(5)
        
        response = requests.get(f"{BASE_URL}/wallet.php?action=balance", 
                              headers=headers)
        if response.status_code == 200:
            print("✅ 速率限制重置后请求成功")
        else:
            print("❌ 速率限制重置后请求仍然失败")

def test_input_validation():
    """测试输入验证增强"""
    print(f"\n{'='*60}")
    print("测试输入验证增强")
    print(f"{'='*60}")
    
    # 测试无效用户名（太短）
    short_username_data = {
        "username": "ab",  # 少于3个字符
        "password": "test123456",
        "email": "test@example.com"
    }
    
    response = requests.post(f"{BASE_URL}/auth.php?action=register", 
                            json=short_username_data)
    result = print_response("用户名过短测试", response)
    
    # 测试无效邮箱格式
    invalid_email_data = {
        "username": "valid_username",
        "password": "test123456",
        "email": "invalid_email_format"
    }
    
    response = requests.post(f"{BASE_URL}/auth.php?action=register", 
                            json=invalid_email_data)
    result = print_response("无效邮箱格式测试", response)
    
    # 测试无效充值金额
    register_data = {
        "username": f"validation_test_{int(time.time())}",
        "password": "test123456",
        "email": f"validation_test_{int(time.time())}@example.com"
    }
    
    response = requests.post(f"{BASE_URL}/auth.php?action=register", 
                            json=register_data)
    
    # 用户登录
    login_data = {
        "username": register_data['username'],
        "password": register_data['password']
    }
    
    response = requests.post(f"{BASE_URL}/auth.php?action=login", 
                            json=login_data)
    result = response.json()
    
    if result and result.get('success'):
        token = result.get('token')
        headers = {'Authorization': f'Bearer {token}'}
        
        # 测试无效充值金额
        invalid_amount_data = {
            "amount": -10.0,  # 负数金额
            "payment_method": "alipay"
        }
        
        response = requests.post(f"{BASE_URL}/wallet.php?action=recharge", 
                              json=invalid_amount_data, headers=headers)
        result = print_response("无效充值金额测试", response)
        
        # 测试金额过大的情况
        too_large_amount_data = {
            "amount": 999999.0,  # 超过限制的大金额
            "payment_method": "alipay"
        }
        
        response = requests.post(f"{BASE_URL}/wallet.php?action=recharge", 
                              json=too_large_amount_data, headers=headers)
        result = print_response("过大充值金额测试", response)

def test_cors_headers():
    """测试CORS配置"""
    print(f"\n{'='*60}")
    print("测试CORS配置")
    print(f"{'='*60}")
    
    # 发送一个预检请求
    response = requests.options(f"{BASE_URL}/auth.php?action=login")
    
    print("预检请求响应头:")
    cors_headers = {
        'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
        'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
        'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers'),
        'Access-Control-Allow-Credentials': response.headers.get('Access-Control-Allow-Credentials')
    }
    
    for key, value in cors_headers.items():
        if value:
            print(f"  {key}: {value}")
        else:
            print(f"  {key}: 未设置")
    
    # 检查是否限制允许的域名
    if cors_headers['Access-Control-Allow-Origin'] and cors_headers['Access-Control-Allow-Origin'] != '*':
        print("✅ CORS配置已限制允许的来源域名")
    else:
        print("⚠️ CORS配置可能过于宽松，建议限制允许的来源域名")

def test_error_handling():
    """测试错误处理改进"""
    print(f"\n{'='*60}")
    print("测试错误处理改进")
    print(f"{'='*60}")
    
    # 测试不存在的方法
    response = requests.post(f"{BASE_URL}/auth.php?action=nonexistent", 
                           json={})
    result = print_response("不存在的方法测试", response)
    
    # 测试错误的请求方法
    response = requests.get(f"{BASE_URL}/auth.php?action=login")
    result = print_response("错误的HTTP方法测试", response)
    
    # 检查错误信息是否暴露系统内部信息
    if result and 'PDOException' in str(result) or 'mysql' in str(result).lower():
        print("❌ 错误信息可能暴露系统内部信息")
    else:
        print("✅ 错误信息处理得当，未暴露系统内部信息")

def main():
    """主测试函数"""
    print("改进后的API测试开始")
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"基础URL: {BASE_URL}")
    
    try:
        # 执行各项测试
        test_jwt_token()
        test_rate_limiting()
        test_input_validation()
        test_cors_headers()
        test_error_handling()
        
        print(f"\n{'='*60}")
        print("所有测试完成")
        print(f"{'='*60}")
        
    except Exception as e:
        print(f"\n测试过程中出现错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # 检查依赖
    try:
        import requests
    except ImportError:
        print("请先安装requests库: pip install requests")
        exit(1)
    
    main()