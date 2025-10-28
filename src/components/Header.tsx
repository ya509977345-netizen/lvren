'use client';

import React from 'react';
import Image from 'next/image';
import Link from 'next/link';

export default function Header() {
  const scrollToSection = (sectionId: string) => {
    setTimeout(() => {
      const element = document.getElementById(sectionId);
      if (element) {
        element.scrollIntoView({ 
          behavior: 'smooth',
          block: 'start'
        });
      } else {
        console.warn(`Element with id '${sectionId}' not found`);
      }
    }, 100);
  };

  const handleMenuClick = (sectionId: string, e: React.MouseEvent | React.TouchEvent) => {
    e.preventDefault();
    scrollToSection(sectionId);
  };

  return (
    <header className="header fixed top-0 left-0 w-full bg-white z-50 shadow-sm">
      <nav className="navbar py-3">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between">
            {/* Logo - 大幅缩小尺寸避免遮挡 */}
            <div className="logo max-w-[60px] flex-shrink-0">
              <Link href="/" className="logo-wrap inline-block">
                <Image
                  src="/律刃.png"
                  alt="律刃 Logo"
                  width={60}
                  height={15}
                  className="logo-img logo-img-active w-full h-auto"
                />
              </Link>
            </div>
            
            {/* 导航菜单 - 确保有充足空间 */}
            <div className="nav-menu flex-1 min-w-0 flex justify-end ml-4">
              <ul className="flex items-center space-x-2 md:space-x-3 lg:space-x-4">
                <li>
                  <button 
                    onMouseEnter={(e) => handleMenuClick('download', e)}
                    onTouchStart={(e) => handleMenuClick('download', e)}
                    className="text-gray-700 hover:text-blue-600 transition-colors bg-transparent border-none cursor-pointer text-xs md:text-sm lg:text-base px-1 py-1"
                  >
                    下载
                  </button>
                </li>
                <li>
                  <button 
                    onMouseEnter={(e) => handleMenuClick('features', e)}
                    onTouchStart={(e) => handleMenuClick('features', e)}
                    className="text-gray-700 hover:text-blue-600 transition-colors bg-transparent border-none cursor-pointer text-xs md:text-sm lg:text-base px-1 py-1"
                  >
                    功能
                  </button>
                </li>
                <li>
                  <button 
                    onMouseEnter={(e) => handleMenuClick('advantages', e)}
                    onTouchStart={(e) => handleMenuClick('advantages', e)}
                    className="text-gray-700 hover:text-blue-600 transition-colors bg-transparent border-none cursor-pointer text-xs md:text-sm lg:text-base px-1 py-1"
                  >
                    优势
                  </button>
                </li>
                <li>
                  <button 
                    onMouseEnter={(e) => handleMenuClick('contact', e)}
                    onTouchStart={(e) => handleMenuClick('contact', e)}
                    className="text-gray-700 hover:text-blue-600 transition-colors bg-transparent border-none cursor-pointer text-xs md:text-sm lg:text-base px-1 py-1"
                  >
                    联系
                  </button>
                </li>
                <li>
                  <Link 
                    href="/pay"
                    className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-xs md:text-sm lg:text-base transition-colors"
                  >
                    授权
                  </Link>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </nav>
    </header>
  );
}
