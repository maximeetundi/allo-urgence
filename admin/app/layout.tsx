'use client';

import { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import ErrorBoundary from '@/components/ErrorBoundary';
import QueryProvider from '@/components/QueryProvider';
import './globals.css';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const isLoginPage = pathname === '/';
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const token = localStorage.getItem('admin_token');
    if (!token && pathname !== '/') {
      router.push('/');
    }
  }, [pathname, router]);

  return (
    <html lang="fr">
      <head>
        <title>Allo Urgence — Admin</title>
        <meta name="description" content="Panneau d'administration Allo Urgence" />
      </head>
      <body className="bg-gray-50 min-h-screen" suppressHydrationWarning>
        <ErrorBoundary>
          <QueryProvider>
            {isLoginPage ? (
              <main className="min-h-screen">{children}</main>
            ) : (
              <div className="flex h-screen overflow-hidden">
                <Sidebar />
                <main className="flex-1 overflow-y-auto">
                  <div className="p-8 max-w-[1400px] mx-auto">
                    {mounted && children}
                  </div>
                </main>
              </div>
            )}
          </QueryProvider>
        </ErrorBoundary>
      </body>
    </html>
  );
}
