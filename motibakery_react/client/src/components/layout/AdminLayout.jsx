import { useState } from 'react';
import { Sidebar } from '@/components/layout/Sidebar';
import { Topbar } from '@/components/layout/Topbar';

export function AdminLayout({ children }) {
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-gray-50">
      <Sidebar isOpen={mobileSidebarOpen} onClose={() => setMobileSidebarOpen(false)} />
      <Topbar onMenuClick={() => setMobileSidebarOpen(true)} />
      <main className="pt-14 md:ml-60">
        <div className="mx-auto max-w-[1280px] p-4 sm:p-6 lg:p-8">{children}</div>
      </main>
    </div>
  );
}
