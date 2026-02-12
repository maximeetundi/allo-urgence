'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import './globals.css';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();

  useEffect(() => {
    const token = localStorage.getItem('admin_token');
    if (!token && !window.location.pathname.includes('/login')) {
      router.push('/');
    }
  }, [router]);

  return (
    <html lang="fr">
      <body className="bg-gray-50">
        <div className="flex h-screen">
          <Sidebar />
          <main className="flex-1 overflow-y-auto p-8">
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
