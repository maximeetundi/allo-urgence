'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { login } from '@/lib/api';
import { AlertCircle, ArrowRight, Activity, Lock, Mail } from 'lucide-react';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [mounted, setMounted] = useState(false);
  const router = useRouter();

  useEffect(() => {
    setMounted(true);
    const token = localStorage.getItem('admin_token');
    if (token) router.push('/dashboard');
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const data = await login(email, password);
      if (data.user?.role === 'admin') {
        localStorage.setItem('admin_token', data.token);
        localStorage.setItem('admin_user', JSON.stringify(data.user));
        router.push('/dashboard');
      } else {
        setError('Accès réservé aux administrateurs. Utilisez l\'application mobile.');
      }
    } catch (err: any) {
      setError(err.message || 'Identifiants invalides');
    } finally {
      setLoading(false);
    }
  };

  if (!mounted) return null;

  return (
    <div className="min-h-screen relative flex items-center justify-center overflow-hidden">
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary-950 via-primary-900 to-indigo-900" />

      {/* Floating orbs */}
      <div className="absolute top-[-10%] right-[-5%] w-[500px] h-[500px] bg-indigo-500/10 rounded-full blur-3xl" />
      <div className="absolute bottom-[-15%] left-[-10%] w-[600px] h-[600px] bg-primary-500/10 rounded-full blur-3xl" />
      <div className="absolute top-[40%] left-[20%] w-[200px] h-[200px] bg-cyan-500/5 rounded-full blur-2xl" />

      {/* Grid pattern */}
      <div className="absolute inset-0 opacity-[0.03]"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23fff' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
        }}
      />

      {/* Login card */}
      <div className="relative z-10 w-full max-w-md mx-4 animate-slide-up">
        <div className="bg-white/[0.07] backdrop-blur-2xl rounded-3xl border border-white/10 p-8 shadow-2xl">
          {/* Logo */}
          <div className="text-center mb-8">
            <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-indigo-500 to-primary-500 flex items-center justify-center shadow-colored">
              <Activity size={28} className="text-white" />
            </div>
            <h1 className="text-2xl font-bold text-white tracking-tight">Allo Urgence</h1>
            <p className="text-primary-300 text-sm mt-1">Panel d'administration</p>
          </div>

          {/* Error */}
          {error && (
            <div className="mb-6 p-3.5 bg-danger-500/10 border border-danger-500/20 rounded-xl flex items-center gap-2.5 text-danger-300 text-sm animate-scale-in">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-xs font-medium text-primary-200 mb-2 ml-1">Adresse email</label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 text-primary-400 w-4 h-4" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl py-3 px-10 text-white placeholder-primary-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:bg-white/10 transition-all text-sm"
                  placeholder="admin@allourgence.ca"
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-medium text-primary-200 mb-2 ml-1">Mot de passe</label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-primary-400 w-4 h-4" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl py-3 px-10 text-white placeholder-primary-400 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 focus:bg-white/10 transition-all text-sm"
                  placeholder="••••••••"
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-indigo-500 to-primary-500 hover:from-indigo-600 hover:to-primary-600 text-white font-semibold py-3 px-6 rounded-xl transition-all duration-200 flex items-center justify-center gap-2 shadow-colored disabled:opacity-50 disabled:cursor-not-allowed active:scale-[0.98]"
            >
              {loading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  Se connecter
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </form>

          {/* Demo accounts */}
          <div className="mt-8 pt-6 border-t border-white/5 text-center">
            <p className="text-[11px] text-primary-400 mb-2 font-medium uppercase tracking-wider">Comptes démo</p>
            <div className="space-y-1.5 text-xs text-primary-300">
              <p><span className="text-primary-200 font-medium">admin@allourgence.ca</span> / admin123</p>
              <p><span className="text-primary-200 font-medium">nurse@allourgence.ca</span> / nurse123</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
