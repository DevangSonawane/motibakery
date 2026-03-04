import { Sidebar } from '@/components/layout/Sidebar';
import { Topbar } from '@/components/layout/Topbar';

export function AdminLayout({ children }) {
  return (
    <div className="min-h-screen bg-gray-50">
      <Sidebar />
      <Topbar />
      <main className="ml-60 pt-14">
        <div className="mx-auto max-w-[1280px] p-8">{children}</div>
      </main>
    </div>
  );
}
