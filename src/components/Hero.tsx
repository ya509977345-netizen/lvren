import React from 'react';
import Link from 'next/link';

export default function Hero() {
  return (
    <div
      className="relative h-screen flex items-center justify-center bg-cover bg-center pt-2"
      style={{
        backgroundImage: 'url(/background.svg)',
        height: '720px'
      }}
    >
      {/* 下载锚点 - 位于页面最顶部 */}
      <div id="download" className="absolute top-0 left-0 w-0 h-0" />
      <div className="absolute inset-0 bg-black bg-opacity-40" />
      <div className="container mx-auto px-4 relative z-10 text-center">
        <div className="carousel-centered">
          <div className="mb-10">
            {/* 律刃图片 */}
            <div className="flex justify-center mb-6">
              <img 
                src="/律刃.png" 
                alt="律刃" 
                className="h-60 md:h-60"
              />
            </div>
            <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">律师案件管理系统</h1>
            <p className="text-white text-lg mb-2">简化办案、释放你的大量时间</p>
          
          </div>
          <div className="flex flex-wrap justify-center gap-4">
            <Link
              href="#"
              className="download-button inline-block bg-transparent hover:bg-white hover:text-gray-900 text-white border border-white px-12 py-4 rounded text-lg uppercase font-medium"
            >
              立即下载
            </Link>          
          </div>

        </div>
      </div>
    </div>
  );
}
