'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  Building2,
  Ticket,
  LogOut,
  ChevronLeft,
  ChevronRight,
  Activity,
  Shield,
} from 'lucide-react';

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', href: '/dashboard' },
  { icon: Users, label: 'Utilisateurs', href: '/users' },
  { icon: Building2, label: 'Hôpitaux', href: '/hospitals' },
  { icon: Ticket, label: 'Tickets', href: '/tickets' },
];

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false);
  const [user, setUser] = useState<any>(null);
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    try {
      const u = localStorage.getItem('admin_user');
      if (u) setUser(JSON.parse(u));
    } catch { }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    router.push('/');
  };

  if (pathname === '/') return null;

  return (
    <aside
      className={`bg-gradient-to-b from-primary-950 via-primary-900 to-primary-950 text-white flex flex-col transition-all duration-300 ease-in-out ${collapsed ? 'w-20' : 'w-64'
        }`}
    >
      {/* Header */}
      <div className="p-5 flex items-center justify-between border-b border-white/5">
        {!collapsed && (
          <div className="flex items-center gap-3 animate-fade-in">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-500 to-primary-500 flex items-center justify-center shadow-colored">
              <Activity size={18} className="text-white" />
            </div>
            <div>
              <span className="font-bold text-sm tracking-tight">Allo Urgence</span>
              <p className="text-[10px] text-primary-300 font-medium">Admin Panel</p>
            </div>
          </div>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="p-2 hover:bg-white/5 rounded-xl transition-colors"
        >
          {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
        </button>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4">
        <ul className="space-y-1">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className={`relative flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 group ${isActive
                      ? 'bg-white/10 text-white shadow-sm'
                      : 'text-primary-200 hover:bg-white/5 hover:text-white'
                    } ${collapsed ? 'justify-center' : ''}`}
                >
                  {isActive && (
                    <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 bg-gradient-to-b from-indigo-400 to-primary-400 rounded-r-full" />
                  )}
                  <Icon size={19} className={isActive ? 'text-indigo-400' : 'group-hover:text-primary-300'} />
                  {!collapsed && <span>{item.label}</span>}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* User + Logout */}
      <div className="p-3 border-t border-white/5 space-y-2">
        {user && !collapsed && (
          <div className="flex items-center gap-3 px-3 py-2 rounded-xl bg-white/5 animate-fade-in">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-primary-400 to-indigo-400 flex items-center justify-center text-xs font-bold">
              {user.prenom?.[0]}{user.nom?.[0]}
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-xs font-medium truncate">{user.prenom} {user.nom}</p>
              <p className="text-[10px] text-primary-300 truncate flex items-center gap-1">
                <Shield size={9} />
                {user.role === 'admin' ? 'Administrateur' : user.role === 'nurse' ? 'Infirmier(ère)' : user.role}
              </p>
            </div>
          </div>
        )}
        <button
          onClick={handleLogout}
          className={`flex items-center gap-3 px-3 py-2.5 text-danger-300 hover:bg-danger-500/10 rounded-xl transition-all w-full text-sm font-medium ${collapsed ? 'justify-center' : ''
            }`}
        >
          <LogOut size={18} />
          {!collapsed && <span>Déconnexion</span>}
        </button>
      </div>
    </aside>
  );
}
