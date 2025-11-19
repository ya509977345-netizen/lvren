#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
API测试脚本 - 测试改进后的API安全性和功能
测试内容：JWT认证、速率限制、输入验证、错误处理、日志记录等
"""

import requests
import json
import time
import random
import hashlib
from datetime import datetime

# 配置
BASE_URL = "https://lvren.cc/api"
API_KEY = "Wang869678"

class APITester:
    def __init__(self, base_url):
        self.base_url = base_url
        self.session = requests.Session()
        self.token = None
        self.user_id = None
        
        # 设置请求头
        self.session.headers.update({
            'Content-Type': 'application/json',
            'User-Agent': 'APITester/1.0'
        })
    
    def print_result(self, test_name, success, message="", response=None):
        """打印测试结果"""
        status = "✓ 通过" if success else "✗ 失败"
        print(f"{test_name}: {status}")
        
        if message:
            print(f"   信息: {message}")
        
        if response and not success:
            print(f"   响应状态: {response.status_code}")
            if response.text:
                try:
                    error_data = response.json()
                    print(f"   错误信息: {error_data.get('message', 'N/A')}")
                except:
                    print(f"   响应内容: {response.text[:200]}...")
        
        print()
    
    def test_cors_headers(self):
        """测试CORS头设置"""
        try:
            response = self.session.options(f"{self.base_url}/auth.php")
            
            cors_headers = {
                'Access-Control-Allow-Origin': 'https://lvren.cc',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                'Access-Control-Allow-Credentials': 'true'
            }
            
            success = True
            for header, expected_value in cors_headers.items():
                actual_value = response.headers.get(header)
                if actual_value != expected_value:
                    print(f"    CORS头 {header}: 期望 '{expected_value}'，实际 '{actual_value}'")
                    success = False
            
            self.print_result("CORS头设置", success)
            return success
            
        except Exception as e:
            self.print_result("CORS头设置", False, f"异常: {str(e)}")
            return False
    
    def test_rate_limiting(self):
        """测试速率限制功能"""
        print("测试速率限制...")
        
        # 连续发送多个请求触发速率限制
        responses = []
        for i in range(11):  # 超过默认限制10次/分钟
            try:
                response = self.session.post(
                    f"{self.base_url}/auth.php?action=login",
                    data=json.dumps({
                        "username": f"testuser{random.randint(1000, 9999)}",
                        "password": "testpass123"
                    })
                )
                responses.append(response)
                
                # 检查速率限制头
                rate_headers = [
                    'X-RateLimit-Limit',
                    'X-RateLimit-Remaining', 
                    'X-RateLimit-Reset'
                ]
                
                for header in rate_headers:
                    if header in response.headers:
                        print(f"    请求 {i+1}: {header}: {response.headers[header]}")
                
                time.sleep(0.1)  # 短暂间隔
                
            except Exception as e:
                print(f"    请求 {i+1} 失败: {str(e)}")
        
        # 检查最后一个请求是否被限制
        last_response = responses[-1] if responses else None
        
        if last_response and last_response.status_code == 429:
            self.print_result("速率限制", True, "成功触发速率限制")
            return True
        else:
            self.print_result("速率限制", False, "未触发速率限制")
            return False
    
    def test_input_validation(self):
        """测试输入验证功能"""
        print("测试输入验证...")
        
        test_cases = [
            {
                "name": "短用户名",
                "data": {"username": "ab", "password": "validpass123"},
                "expected_error": "长度不能少于"
            },
            {
                "name": "空密码", 
                "data": {"username": "validuser", "password": ""},
                "expected_error": "必需"
            },
            {
                "name": "无效邮箱格式",
                "data": {"username": "validuser", "password": "validpass123", "email": "invalid-email"},
                "expected_error": "邮箱地址"
            }
        ]
        
        success_count = 0
        
        for test_case in test_cases:
            try:
                response = self.session.post(
                    f"{self.base_url}/auth.php?action=register",
                    data=json.dumps(test_case["data"])
                )
                
                if response.status_code == 400:
                    error_data = response.json()
                    if test_case["expected_error"] in str(error_data):
                        print(f"    {test_case['name']}: 通过")
                        success_count += 1
                    else:
                        print(f"    {test_case['name']}: 失败 - 未找到预期错误信息")
                else:
                    print(f"    {test_case['name']}: 失败 - 状态码 {response.status_code}")
                    
            except Exception as e:
                print(f"    {test_case['name']}: 异常 - {str(e)}")
        
        success = success_count == len(test_cases)
        self.print_result("输入验证", success, f"通过 {success_count}/{len(test_cases)} 个测试用例")
        return success
    
    def test_jwt_authentication(self):
        """测试JWT认证功能"""
        print("测试JWT认证...")
        
        # 1. 测试无效token
        try:
            self.session.headers.update({'Authorization': 'Bearer invalid_token'})
            response = self.session.post(f"{self.base_url}/auth.php?action=verify")
            
            if response.status_code == 401:
                print("    无效token验证: 通过")
            else:
                print("    无效token验证: 失败")
                return False
                
        except Exception as e:
            print(f"    无效token验证异常: {str(e)}")
            return False
        
        # 2. 注册测试用户
        test_username = f"testuser_{int(time.time())}"
        test_password = "TestPass123!"
        test_email = f"{test_username}@test.com"
        
        try:
            response = self.session.post(
                f"{self.base_url}/auth.php?action=register",
                data=json.dumps({
                    "username": test_username,
                    "password": test_password,
                    "email": test_email
                })
            )
            
            if response.status_code == 200:
                print("    用户注册: 通过")
            else:
                print("    用户注册: 失败")
                return False
                
        except Exception as e:
            print(f"    用户注册异常: {str(e)}")
            return False
        
        # 3. 登录获取token
        try:
            response = self.session.post(
                f"{self.base_url}/auth.php?action=login",
                data=json.dumps({
                    "username": test_username,
                    "password": test_password
                })
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'token' in data:
                    self.token = data['token']
                    self.user_id = data['user']['id']
                    print("    用户登录: 通过")
                else:
                    print("    用户登录: 失败 - 未获取到token")
                    return False
            else:
                print("    用户登录: 失败")
                return False
                
        except Exception as e:
            print(f"    用户登录异常: {str(e)}")
            return False
        
        # 4. 验证token
        try:
            self.session.headers.update({'Authorization': f'Bearer {self.token}'})
            response = self.session.post(f"{self.base_url}/auth.php?action=verify")
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'user' in data:
                    print("    Token验证: 通过")
                else:
                    print("    Token验证: 失败")
                    return False
            else:
                print("    Token验证: 失败")
                return False
                
        except Exception as e:
            print(f"    Token验证异常: {str(e)}")
            return False
        
        self.print_result("JWT认证", True, "所有认证测试通过")
        return True
    
    def test_wallet_functionality(self):
        """测试钱包功能"""
        if not self.token:
            print("    跳过钱包测试 - 需要先登录")
            return False
        
        print("测试钱包功能...")
        
        try:
            # 获取余额
            response = self.session.post(f"{self.base_url}/wallet.php?action=get_balance")
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success') and 'balance' in data:
                    print(f"    余额查询: 通过 - 余额: {data['balance']}")
                else:
                    print("    余额查询: 失败")
                    return False
            else:
                print("    余额查询: 失败")
                return False
                
        except Exception as e:
            print(f"    余额查询异常: {str(e)}")
            return False
        
        self.print_result("钱包功能", True, "余额查询通过")
        return True
    
    def test_error_handling(self):
        """测试错误处理"""
        print("测试错误处理...")
        
        test_cases = [
            {
                "name": "无效接口",
                "url": f"{self.base_url}/auth.php?action=invalid",
                "expected_code": 404
            },
            {
                "name": "GET方法",
                "url": f"{self.base_url}/auth.php",
                "method": "GET",
                "expected_code": 405
            }
        ]
        
        success_count = 0
        
        for test_case in test_cases:
            try:
                method = test_case.get('method', 'POST')
                
                if method == 'GET':
                    response = self.session.get(test_case['url'])
                else:
                    response = self.session.post(test_case['url'])
                
                if response.status_code == test_case['expected_code']:
                    print(f"    {test_case['name']}: 通过")
                    success_count += 1
                else:
                    print(f"    {test_case['name']}: 失败 - 期望 {test_case['expected_code']}, 实际 {response.status_code}")
                    
            except Exception as e:
                print(f"    {test_case['name']}: 异常 - {str(e)}")
        
        success = success_count == len(test_cases)
        self.print_result("错误处理", success, f"通过 {success_count}/{len(test_cases)} 个测试用例")
        return success
    
    def run_all_tests(self):
        """运行所有测试"""
        print("=" * 60)
        print("API接口全面测试")
        print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"测试地址: {self.base_url}")
        print("=" * 60)
        print()
        
        test_results = []
        
        # 运行各个测试
        test_results.append(("CORS头设置", self.test_cors_headers()))
        test_results.append(("输入验证", self.test_input_validation()))
        test_results.append(("JWT认证", self.test_jwt_authentication()))
        
        if self.token:  # 只有在登录成功后才测试钱包
            test_results.append(("钱包功能", self.test_wallet_functionality()))
        
        test_results.append(("错误处理", self.test_error_handling()))
        test_results.append(("速率限制", self.test_rate_limiting()))
        
        # 汇总结果
        print("=" * 60)
        print("测试结果汇总")
        print("=" * 60)
        
        passed_count = sum(1 for _, result in test_results if result)
        total_count = len(test_results)
        
        for test_name, result in test_results:
            status = "✓ 通过" if result else "✗ 失败"
            print(f"{test_name}: {status}")
        
        print(f"\n总测试: {total_count} 个")
        print(f"通过: {passed_count} 个")
        print(f"失败: {total_count - passed_count} 个")
        
        success_rate = (passed_count / total_count) * 100
        print(f"成功率: {success_rate:.1f}%")
        
        if success_rate >= 80:
            print("\n🎉 API接口测试通过！安全性改进已生效。")
        else:
            print("\n⚠️  API接口存在一些问题，请检查改进。")
        
        return success_rate >= 80

def main():
    """主函数"""
    tester = APITester(BASE_URL)
    
    try:
        success = tester.run_all_tests()
        exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n测试被用户中断")
        exit(1)
    except Exception as e:
        print(f"\n测试过程中出现异常: {str(e)}")
        exit(1)

if __name__ == "__main__":
    main()