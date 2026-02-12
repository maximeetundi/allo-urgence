'use client';

import { useState } from 'react';
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
  Stethoscope,
} from 'lucide-react';

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', href: '/dashboard' },
  { icon: Users, label: 'Utilisateurs', href: '/users' },
  { icon: Building2, label: 'Hôpitaux', href: '/hospitals' },
  { icon: Ticket, label: 'Tickets', href: '/tickets' },
];

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false);
  const pathname = usePathname();
  const router = useRouter();

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    router.push('/');
  };

  // Don't show sidebar on login page
  if (pathname === '/') return null;

  return (
    <aside
      className={`bg-primary-900 text-white transition-all duration-300 flex flex-col ${
        collapsed ? 'w-20' : 'w-64'
      }`}
    >
      <div className="p-6 flex items-center justify-between">
        {!collapsed && (
          <div className="flex items-center gap-3">
            <span className="text-2xl">🏥</span>
            <span className="font-bold text-lg">Allo Urgence</span>
          </div>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="p-2 hover:bg-primary-800 rounded-lg transition-colors"
        >
          {collapsed ? <ChevronRight size={20} /> : <ChevronLeft size={20} />}
        </button>
      </div>

      <nav className="flex-1 px-4 py-4">
        <ul className="space-y-2">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href;
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                    isActive
                      ? 'bg-primary-700 text-white'
                      : 'text-primary-100 hover:bg-primary-800'
                  }`}
                >
                  <Icon size={20} />
                  {!collapsed && <span>{item.label}</span>}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="p-4 border-t border-primary-800">
        <button
          onClick={handleLogout}
          className={`flex items-center gap-3 px-4 py-3 text-danger-300 hover:bg-danger-900/30 rounded-lg transition-colors w-full ${
            collapsed ? 'justify-center' : ''
          }`}
        >
          <LogOut size={20} />
          {!collapsed && <span>Déconnexion</span>}
        </button>
      </div>
    </aside>
  );
}
