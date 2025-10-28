'use client';

import React, { useState } from 'react';
import Link from 'next/link';

export default function PayPage() {
  const [selectedPlan, setSelectedPlan] = useState<'personal' | 'professional'>('personal');
  const [showAuthModal, setShowAuthModal] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-200 flex items-center justify-center p-4">
      <div className="w-full max-w-4xl bg-white rounded-xl shadow-lg overflow-hidden">
        {/* Header */}
        <header className="bg-gradient-to-r from-gray-800 to-blue-900 text-white p-6 text-center">
          <h1 className="text-2xl font-bold mb-2">律刃案件管理系统</h1>
          <p className="text-blue-200">专业版 - 授权控制面板</p>
        </header>
        
        {/* Status Bar */}
        <div className="flex justify-between items-center p-4 bg-gray-50 border-b border-gray-200">
          <div className="flex items-center">
            <div className="w-3 h-3 bg-orange-500 rounded-full mr-2"></div>
            <span> <strong>激活</strong></span>
          </div>
          
        </div>
        
        {/* Main Content */}
        <div className="md:flex">
          {/* Purchase Section */}
          <div className="w-full p-6 bg-gray-50">
            <h2 className="text-xl font-semibold text-gray-800 mb-4 pb-2 border-b-2 border-blue-500">购买会员</h2>
            
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Personal Plan */}
                <div 
                  className={`border rounded-lg p-4 cursor-pointer transition-colors ${selectedPlan === 'personal' ? 'border-blue-500 bg-blue-50' : 'border-gray-300'}`}
                  onClick={() => setSelectedPlan('personal')}
                >
                  <div className="text-lg font-semibold text-gray-800">个人版</div>
                  <div className="text-2xl font-bold text-blue-600 my-2">¥129 / 年</div>
                  <ul className="space-y-2 mt-3">
                    <li className="flex items-center text-sm text-gray-700">
                      <span className="text-green-500 mr-2">✓</span>
                      所有功能无限制使用
                    </li>
                    <li className="flex items-center text-sm text-gray-700">
                      <span className="text-green-500 mr-2">✓</span>
                      优先技术支持
                    </li>
                    <li className="flex items-center text-sm text-gray-700">
                      <span className="text-green-500 mr-2">✓</span>
                      免费更新至最新版本
                    </li>
                    <li className="flex items-center text-sm text-gray-700">
                      <span className="text-green-500 mr-2">✓</span>
                      单设备授权
                    </li>
                  </ul>
                </div>
                
                {/* Professional Plan */}
                <div 
                  className={`border rounded-lg p-4 cursor-pointer transition-colors ${selectedPlan === 'professional' ? 'border-blue-500 bg-blue-50' : 'border-gray-300'}`}
                  onClick={() => setSelectedPlan('professional')}
                >
                  <div className="text-lg font-semibold text-gray-800">专业版</div>
                  <div className="text-2xl font-bold text-blue-600 my-2">¥269 / 年</div>
                  <ul className="space-y-2 mt-3">
                    <li className="flex items-center text-sm text-gray-700">
                      <span className="text-green-500 mr-2">✓</span>
                      所有个人版功能
                    </li>
                    <li className="flex items-center text-sm text-gray-700">
                      <span className="text-green-500 mr-2">✓</span>
                      3设备同时使用
                    </li>
                    <li className="flex items-center text-sm text-gray-700">
                      <span className="text-green-500 mr-2">✓</span>
                      远程协助服务
                    </li>
                    <li className="flex items-center text-sm text-gray-700">
                      <span className="text-green-500 mr-2">✓</span>
                      专属客服通道
                    </li>
                  </ul>
                </div>
              </div>
              
              <button 
                className="w-full bg-orange-600 text-white py-2 px-4 rounded-md hover:bg-orange-700 transition-colors"
                onClick={() => setShowAuthModal(true)}
              >
                立即购买
              </button>
              
              <div className="bg-blue-50 p-4 rounded-md text-sm text-gray-700">
                <h3 className="font-semibold text-gray-800 mb-2">离线授权说明</h3>
                <p>一旦授权成功，您的软件将在授权期内完全脱机使用，无需联网验证。授权文件将绑定至您的设备，请妥善保管。</p>
              </div>
            </div>
          </div>
        </div>
        
        {/* Footer */}
        <footer className="bg-gray-50 p-4 text-center text-gray-600 text-sm border-t border-gray-200">
          <p>© 2023 律刃案件管理系统 - 所有权利保留 | 技术支持: support@example.com</p>
        </footer>
      </div>

      {/* Auth Modal */}
      {showAuthModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md">
            <div className="p-6">
              <h2 className="text-xl font-semibold text-gray-800 mb-4 pb-2 border-b-2 border-blue-500">用户账户</h2>
              
              <div className="space-y-4">
                <div className="hidden">
                  <img 
                    src="/erweima.png" 
                    alt="二维码" 
                    width={200} 
                    height={200} 
                    className="mx-auto"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">电子邮箱</label>
                  <input 
                    type="email" 
                    placeholder="请输入您的邮箱"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    onChange={(e) => {
                      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                      const emailValid = emailRegex.test(e.target.value);
                      const emailError = document.getElementById('email-error');
                      if (emailError) {
                        emailError.textContent = emailValid ? '' : '请输入有效的邮箱地址';
                      }
                    }}
                  />
                  <div id="email-error" className="text-red-500 text-sm h-4"></div>
                  <div className="text-sm text-gray-600">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">机器码</label>
                      <input 
                        type="text"
                        placeholder="XXXX-XXXX-XXXX-XXXX"
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        onChange={(e) => {
                          const machineCodeRegex = /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
                          const value = e.target.value.toUpperCase();
                          const machineCodeValid = machineCodeRegex.test(value);
                          const machineCodeError = document.getElementById('machine-code-error');
                          if (machineCodeError) {
                            machineCodeError.textContent = machineCodeValid ? '' : '请输入正确的机器码格式 (XXXX-XXXX-XXXX-XXXX)';
                          }
                          e.target.value = value;
                        }}
                      />
                      <div id="machine-code-error" className="text-red-500 text-sm h-4"></div>
                    </div>                  
                  </div>
                </div>
                
                <button 
                  className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 transition-colors confirm-button"
                  onClick={() => {
                    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                    const machineCodeRegex = /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
                    const emailInput = document.querySelector('input[type="email"]') as HTMLInputElement;
                    const machineCodeInput = document.querySelector('input[type="text"]') as HTMLInputElement;
                    
                    if (!emailRegex.test(emailInput.value)) {
                      const emailError = document.getElementById('email-error');
                      if (emailError) emailError.textContent = '请输入有效的邮箱地址';
                      return;
                    }
                    
                    if (!machineCodeRegex.test(machineCodeInput.value)) {
                      const machineCodeError = document.getElementById('machine-code-error');
                      if (machineCodeError) machineCodeError.textContent = '请输入正确的机器码格式 (XXXX-XXXX-XXXX-XXXX)';
                      return;
                    }
                    
                    const qrCodeContainer = document.querySelector('.hidden') as HTMLDivElement;
                    if (qrCodeContainer) {
                      qrCodeContainer.classList.remove('hidden');
                      window.scrollTo({
                        top: qrCodeContainer.offsetTop - 20,
                        behavior: 'smooth'
                      });
                    }
                  }}
                >
                  确认购买
                </button>
                
                <button 
                  className="w-full bg-gray-200 text-gray-800 py-2 px-4 rounded-md hover:bg-gray-300 transition-colors mt-2"
                  onClick={() => setShowAuthModal(false)}
                >
                  取消
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}