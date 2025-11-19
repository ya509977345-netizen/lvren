#!/usr/bin/env python3
"""
乐人软件API测试脚本
测试所有API接口的功能和性能
"""

import requests
import json
import time
from datetime import datetime

# 基础配置
BASE_URL = "https://lvren.cc/api"  # 根据实际情况修改
test_users = []

def print_response(title, response):
    """格式化打印响应结果"""
    print(f"\n{'='*60}")
    print(f"{title}")
    print(f"{'='*60}")
    print(f"URL: {response.url}")
    print(f"状态码: {response.status_code}")
    if response.status_code == 200:
        try:
            data = response.json()
            print(f"响应数据: {json.dumps(data, indent=2, ensure_ascii=False)}")
        except:
            print(f"响应内容: {response.text}")
    else:
        print(f"错误信息: {response.text}")
    return response.json() if response.status_code == 200 else None

def test_database_connection():
    """测试数据库连接"""
    try:
        response = requests.get(f"{BASE_URL}/config.php")
        return print_response("数据库连接测试", response)
    except Exception as e:
        print(f"数据库连接测试失败: {e}")
        return None

def test_auth_api():
    """测试认证接口"""
    global test_users
    
    # 测试用户注册
    register_data = {
        "username": f"testuser_{int(time.time())}",
        "password": "test123456",
        "email": f"test{int(time.time())}@example.com"
    }
    
    response = requests.post(f"{BASE_URL}/auth.php?action=register", 
                            json=register_data)
    result = print_response("用户注册测试", response)
    
    if result and result.get('success'):
        user_id = result.get('user_id')
        test_users.append({
            'user_id': user_id,
            'username': register_data['username'],
            'password': register_data['password']
        })
    
    # 测试用户登录
    if test_users:
        login_data = {
            "username": test_users[0]['username'],
            "password": test_users[0]['password']
        }
        
        response = requests.post(f"{BASE_URL}/auth.php?action=login", 
                                json=login_data)
        result = print_response("用户登录测试", response)
        
        if result and result.get('success'):
            token = result.get('token')
            test_users[0]['token'] = token
            
            # 使用Token进行验证
            headers = {'Authorization': f'Bearer {token}'}
            response = requests.post(f"{BASE_URL}/auth.php?action=verify", 
                                    headers=headers)
            print_response("Token验证测试", response)
    
    # 测试错误情况
    # 空数据测试
    response = requests.post(f"{BASE_URL}/auth.php?action=login", 
                            json={})
    print_response("空数据登录测试", response)
    
    # 错误密码测试
    wrong_login = {
        "username": "nonexistent",
        "password": "wrongpassword"
    }
    response = requests.post(f"{BASE_URL}/auth.php?action=login", 
                            json=wrong_login)
    print_response("错误凭证登录测试", response)

def test_wallet_api():
    """测试钱包接口"""
    if not test_users or 'token' not in test_users[0]:
        print("\n跳过钱包测试 - 需要先登录获取Token")
        return
    
    token = test_users[0]['token']
    headers = {'Authorization': f'Bearer {token}'}
    
    # 测试获取余额
    response = requests.get(f"{BASE_URL}/wallet.php?action=balance", 
                          headers=headers)
    result = print_response("获取余额测试", response)
    
    # 测试充值记录
    recharge_data = {
        "amount": 100.0,
        "payment_method": "alipay"
    }
    response = requests.post(f"{BASE_URL}/wallet.php?action=recharge", 
                           json=recharge_data, headers=headers)
    result = print_response("充值测试", response)
    
    # 再次获取余额查看变化
    response = requests.get(f"{BASE_URL}/wallet.php?action=balance", 
                          headers=headers)
    print_response("充值后余额查询", response)
    
    # 测试获取充值历史
    response = requests.get(f"{BASE_URL}/wallet.php?action=recharge_history", 
                          headers=headers)
    print_response("充值历史查询", response)
    
    # 测试扣费
    deduct_data = {
        "amount": 10.0,
        "description": "软件功能使用扣费"
    }
    response = requests.post(f"{BASE_URL}/wallet.php?action=deduct", 
                           json=deduct_data, headers=headers)
    print_response("扣费测试", response)
    
    # 余额不足扣费测试
    big_deduct = {
        "amount": 1000.0,
        "description": "大额扣费测试"
    }
    response = requests.post(f"{BASE_URL}/wallet.php?action=deduct", 
                           json=big_deduct, headers=headers)
    print_response("余额不足扣费测试", response)

def test_license_api():
    """测试授权接口"""
    if not test_users or 'token' not in test_users[0]:
        print("\n跳过授权测试 - 需要先登录获取Token")
        return
    
    token = test_users[0]['token']
    headers = {'Authorization': f'Bearer {token}'}
    
    # 测试检查授权（无授权情况）
    response = requests.get(f"{BASE_URL}/license.php?action=check&software_id=test_app", 
                          headers=headers)
    print_response("授权检查测试（无授权）", response)
    
    # 测试创建授权
    create_data = {
        "software_id": "test_app",
        "duration_days": 30,
        "max_devices": 3
    }
    response = requests.post(f"{BASE_URL}/license.php?action=create", 
                           json=create_data, headers=headers)
    result = print_response("创建授权测试", response)
    
    if result and result.get('success'):
        license_id = result['license']['id']
        
        # 测试检查授权（有授权情况）
        response = requests.get(f"{BASE_URL}/license.php?action=check&software_id=test_app", 
                              headers=headers)
        print_response("授权检查测试（有授权）", response)
        
        # 测试获取用户所有授权
        response = requests.get(f"{BASE_URL}/license.php?action=list", 
                              headers=headers)
        print_response("授权列表查询", response)
        
        # 测试授权续期
        renew_data = {
            "license_id": license_id,
            "duration_days": 15
        }
        response = requests.post(f"{BASE_URL}/license.php?action=renew", 
                               json=renew_data, headers=headers)
        print_response("授权续期测试", response)
        
        # 测试禁用授权
        disable_data = {
            "license_id": license_id
        }
        response = requests.post(f"{BASE_URL}/license.php?action=disable", 
                               json=disable_data, headers=headers)
        print_response("禁用授权测试", response)
        
        # 禁用后再次检查授权
        response = requests.get(f"{BASE_URL}/license.php?action=check&software_id=test_app", 
                              headers=headers)
        print_response("禁用后授权检查", response)

def test_performance():
    """性能测试"""
    if not test_users or 'token' not in test_users[0]:
        print("\n跳过性能测试 - 需要先登录获取Token")
        return
    
    token = test_users[0]['token']
    headers = {'Authorization': f'Bearer {token}'}
    
    print(f"\n{'='*60}")
    print("性能测试")
    print(f"{'='*60}")
    
    # 并发测试余额查询
    start_time = time.time()
    requests_count = 10
    
    for i in range(requests_count):
        requests.get(f"{BASE_URL}/wallet.php?action=balance", headers=headers)
    
    end_time = time.time()
    avg_time = (end_time - start_time) / requests_count
    
    print(f"并发请求数量: {requests_count}")
    print(f"总耗时: {end_time - start_time:.2f}秒")
    print(f"平均响应时间: {avg_time:.2f}秒")

def test_error_handling():
    """错误处理测试"""
    print(f"\n{'='*60}")
    print("错误处理测试")
    print(f"{'='*60}")
    
    # 测试不存在的接口
    response = requests.get(f"{BASE_URL}/auth.php?action=nonexistent")
    print_response("不存在的接口测试", response)
    
    # 测试错误的HTTP方法
    response = requests.get(f"{BASE_URL}/auth.php?action=login")
    print_response("错误的HTTP方法测试", response)
    
    # 测试无效的JSON数据
    headers = {'Content-Type': 'application/json'}
    response = requests.post(f"{BASE_URL}/auth.php?action=login", 
                           data="invalid json", headers=headers)
    print_response("无效JSON数据测试", response)
    
    # 测试空Token
    headers = {'Authorization': 'Bearer '}
    response = requests.get(f"{BASE_URL}/wallet.php?action=balance", headers=headers)
    print_response("空Token测试", response)
    
    # 测试无效Token
    headers = {'Authorization': 'Bearer invalid_token_123'}
    response = requests.get(f"{BASE_URL}/wallet.php?action=balance", headers=headers)
    print_response("无效Token测试", response)

def main():
    """主测试函数"""
    print("乐人软件API测试开始")
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"基础URL: {BASE_URL}")
    
    try:
        # 按顺序执行测试
        test_database_connection()
        test_auth_api()
        test_wallet_api()
        test_license_api()
        test_performance()
        test_error_handling()
        
        print(f"\n{'='*60}")
        print("所有测试完成")
        print(f"{'='*60}")
        
        if test_users:
            print(f"测试用户信息:")
            for user in test_users:
                print(f"  - 用户名: {user['username']}")
                if 'token' in user:
                    print(f"    Token: {user['token'][:20]}...")
        
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