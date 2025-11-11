import React from 'react';
import Link from 'next/link';
import BackToTop from './BackToTop';

export default function Footer() {
  return (
    <footer id="contact" className="footer bg-white">
      {/* Links section */}
      <div className="border-t border-gray-200 py-10">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div>
              <ul className="space-y-2">
                <li>
                  <Link href="https://pc.qq.com/detail/10/detail_25550.html" className="text-gray-600 hover:text-gray-900">
                    提建议
                  </Link>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Copyright section */}
      <div className="border-t border-gray-200 py-6">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-6 gap-4 text-sm text-gray-600">
            <div className="md:col-span-1">
              <p>云南律刃科技有限公司版权所有</p>
            </div>
            <div className="md:col-span-1">
              <p>©律刃 2018-2025</p>
            </div>
            <div className="md:col-span-1">
              <Link href="http://beian.miit.gov.cn" target="_blank" className="hover:text-gray-900">
                滇ICP备2025072685号-1
              </Link>
            </div>
            <div className="md:col-span-2">
              <Link
                href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=36010902000181"
                target="_blank"
                className="hover:text-gray-900 flex items-center"
              >
                <img
                  src="/律刃.png"
                  alt="律刃图标"
                  className="w-4 h-4 mr-1"
                />
                滇公网安备          号
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Back to top button */}
      <BackToTop />
    </footer>
  );
}
