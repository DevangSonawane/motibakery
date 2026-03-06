import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Cake, IndianRupee, Users, ClipboardList, LogOut } from 'lucide-react';
import { routes } from '@/config/routes';
import { logoutFromSupabase } from '@/lib/supabaseAuth';
import { useAuthStore } from '@/stores/authStore';
import appLogo from '@/assets/images-3.png';

const navItems = [
  { to: routes.dashboard, label: 'Dashboard', icon: LayoutDashboard },
  { to: routes.products, label: 'Products', icon: Cake },
  { to: routes.pricing, label: 'Pricing Rules', icon: IndianRupee },
  { to: routes.users, label: 'Users', icon: Users },
  { to: routes.orders, label: 'Orders', icon: ClipboardList },
];

function SidebarContent({ user, onLogout, onNavigate }) {
  return (
    <div className="flex h-full flex-col">
      <div className="border-b border-sidebar-border px-5 py-6">
        <img src={appLogo} alt="Motibakery logo" className="h-12 w-auto object-contain" />
        <p className="mt-1 text-xs text-sidebar-text/80">Admin CMS</p>
      </div>

      <nav className="space-y-1 px-3 py-4">
        {navItems.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            onClick={onNavigate}
            className={({ isActive }) =>
              [
                'flex h-11 items-center gap-3 rounded-r-md border-l-4 px-4 text-sm font-medium transition-colors',
                isActive
                  ? 'border-l-brand bg-white/10 text-white'
                  : 'border-l-transparent text-sidebar-text hover:bg-white/5 hover:text-white',
              ].join(' ')
            }
          >
            <Icon className="h-4 w-4" />
            {label}
          </NavLink>
        ))}
      </nav>

      <div className="mt-auto border-t border-sidebar-border p-4">
        <p className="text-sm font-medium text-white">{user?.name || 'Admin User'}</p>
        <p className="text-xs uppercase tracking-wide">{user?.role || 'admin'}</p>
        <button
          type="button"
          onClick={onLogout}
          className="mt-3 inline-flex w-full items-center justify-center gap-2 rounded-md border border-sidebar-border px-3 py-2 text-sm hover:bg-white/5"
        >
          <LogOut className="h-4 w-4" />
          Logout
        </button>
      </div>
    </div>
  );
}

export function Sidebar({ isOpen = false, onClose = () => {} }) {
  const user = useAuthStore((state) => state.user);
  const token = useAuthStore((state) => state.token);
  const clearAuth = useAuthStore((state) => state.clearAuth);

  const handleLogout = async () => {
    try {
      await logoutFromSupabase(token);
    } finally {
      clearAuth();
    }
  };

  return (
    <>
      <aside className="fixed left-0 top-0 hidden h-screen w-60 border-r border-sidebar-border bg-sidebar-bg text-sidebar-text md:block">
        <SidebarContent user={user} onLogout={handleLogout} />
      </aside>

      <div
        className={[
          'fixed inset-0 z-40 bg-black/40 transition-opacity md:hidden',
          isOpen ? 'opacity-100' : 'pointer-events-none opacity-0',
        ].join(' ')}
        onClick={onClose}
      />

      <aside
        className={[
          'fixed left-0 top-0 z-[60] h-screen w-72 max-w-[85vw] border-r border-sidebar-border bg-sidebar-bg text-sidebar-text shadow-2xl transition-transform transform md:hidden',
          isOpen ? 'translate-x-0' : '-translate-x-full',
        ].join(' ')}
      >
        <SidebarContent user={user} onLogout={handleLogout} onNavigate={onClose} />
      </aside>
    </>
  );
}
