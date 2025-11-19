import React from 'react';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";

export default function Advantages() {
  return (
    <div id="advantages" className="bg-gray-50 py-20">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
          <div className="md:col-span-5">
            <div className="mt-4 mb-6">
              <h2 className="text-3xl font-bold mb-4">我们的优势在哪里?</h2>
              <p className="text-gray-700">
                不依赖网络，办公、开庭、会见均可查阅法律法规，操作便捷，使用方便，适用大部分律师的使用场景。
              </p>
            </div>
          </div>

          <div className="md:col-span-5 md:col-start-8">
            <Accordion type="single" collapsible className="w-full">
              <AccordionItem value="item-1">
                <AccordionTrigger className="text-lg font-medium">
                  案件管理
                </AccordionTrigger>
                <AccordionContent>
                  从接待咨询、谈案件、处理案件、文书生成、知识管理、归档功能一应俱全。
                </AccordionContent>
              </AccordionItem>

              <AccordionItem value="item-2">
                <AccordionTrigger className="text-lg font-medium">
                  多种工具协同
                </AccordionTrigger>
                <AccordionContent>
                  法规摘录、Ai助理、谈案录音、自动归档、待办清单、业绩分类查看、一键导出案件表、一键导出证据目录、证据册并添加页码。
                </AccordionContent>
              </AccordionItem>

              <AccordionItem value="item-3">
                <AccordionTrigger className="text-lg font-medium">
                  释放大量工作时间
                </AccordionTrigger>
                <AccordionContent>
                  当您使用本系统后，会发现原来办案是如此轻松，过去2+天才能处理的工作，现在只需要2个小时。
                </AccordionContent>
              </AccordionItem>
            </Accordion>
          </div>
        </div>
      </div>
    </div>
  );
}
