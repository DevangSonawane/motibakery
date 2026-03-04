import { Bell, Search } from 'lucide-react';
import { useAuthStore } from '@/stores/authStore';

export function Topbar() {
  const user = useAuthStore((state) => state.user);

  return (
    <header className="fixed left-60 right-0 top-0 z-10 flex h-14 items-center border-b border-gray-200 bg-white px-8">
      <div className="relative w-full max-w-md">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
        <input
          type="text"
          placeholder="Search..."
          className="h-9 w-full rounded-md border border-gray-200 pl-9 pr-3 text-sm outline-none ring-brand/20 placeholder:text-gray-400 focus:ring-2"
        />
      </div>

      <div className="ml-auto flex items-center gap-4">
        <button type="button" className="rounded-md p-2 text-gray-500 transition hover:bg-gray-100 hover:text-gray-800">
          <Bell className="h-5 w-5" />
        </button>
        <div className="text-sm font-medium text-gray-700">{user?.name || 'Admin User'}</div>
      </div>
    </header>
  );
}
