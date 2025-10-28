'use client';
import React, { useState } from 'react';
import Image from 'next/image';

export default function Features() {
  const [selectedImage, setSelectedImage] = useState<string | null>(null);

  const features = [
    {
      title: '案件管理',
      description: '一案一号一页面，录入便捷，检索方便，一键生成文书，一键生成证据册，批案录入模式，法律法规检索，文档管理',
      image: '/主界面.png'
    },
    {
      title: '接入AI一键生成各类文书',
      description: '引入强大的AI引擎，根据案件信息自拟起诉状、反诉状、答辩状、辩论意见、法律分析，也可以进行法律问答。',
      image: '/AI助理.png'
    },
    {
      title: '知识管理井然有序',
      description: '每个案由独立的知识库，方便添加查找和个案选取。便于长期积累，形成自己的知识库。',
      image: '/知识管理.png'
    }
  ];

  return (
    <div id="features" className="py-20">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <div key={index} className="flex flex-col">
              <div className="mb-6">
                <h2 className="text-2xl font-bold mb-3">{feature.title}</h2>
                <p className="text-gray-700">{feature.description}</p>
              </div>
              <div 
                className="mt-auto cursor-pointer" 
                onClick={() => setSelectedImage(feature.image)}
              >
                <Image
                  src={feature.image}
                  alt={feature.title}
                  width={400}
                  height={300}
                  className="w-full h-auto max-h-60 rounded-lg shadow-md hover:shadow-lg transition-shadow"
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      {selectedImage && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4"
          onClick={() => setSelectedImage(null)}
        >
          <div className="relative max-w-4xl w-full max-h-[90vh]">
            <Image
              src={selectedImage}
              alt="放大预览"
              width={1200}
              height={900}
              className="w-full h-auto rounded-lg"
            />
          </div>
        </div>
      )}
    </div>
  );
}
