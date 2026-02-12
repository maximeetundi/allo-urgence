'use client';

import { useState, useEffect } from 'react';
import { getDashboardStats, getHospitals, getTickets, getUsers } from '@/lib/api';
import {
  Users,
  Building2,
  Ticket,
  Clock,
  TrendingUp,
  Activity,
  ArrowUpRight,
  Heart,
  Zap,
} from 'lucide-react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Area,
  AreaChart,
} from 'recharts';

const COLORS = ['#6366f1', '#3b82f6', '#22c55e', '#f59e0b', '#ef4444'];

const priorityLabels: Record<number, string> = {
  1: 'P1 — Réanimation',
  2: 'P2 — Très urgent',
  3: 'P3 — Urgent',
  4: 'P4 — Moins urgent',
  5: 'P5 — Non urgent',
};

const priorityColors: Record<number, string> = {
  1: 'bg-red-100 text-red-700',
  2: 'bg-orange-100 text-orange-700',
  3: 'bg-yellow-100 text-yellow-700',
  4: 'bg-blue-100 text-blue-700',
  5: 'bg-green-100 text-green-700',
};

interface Stats {
  totalUsers: number;
  totalHospitals: number;
  activeTickets: number;
  avgWaitTime: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats>({
    totalUsers: 0,
    totalHospitals: 0,
    activeTickets: 0,
    avgWaitTime: 0,
  });
  const [ticketsByStatus, setTicketsByStatus] = useState<any[]>([]);
  const [ticketsByPriority, setTicketsByPriority] = useState<any[]>([]);
  const [recentTickets, setRecentTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      const [usersData, hospitalsData, ticketsData] = await Promise.all([
        getUsers().catch(() => []),
        getHospitals().catch(() => []),
        getTickets().catch(() => []),
      ]);

      const users = Array.isArray(usersData) ? usersData : [];
      const hospitals = Array.isArray(hospitalsData) ? hospitalsData : [];
      const tickets = Array.isArray(ticketsData) ? ticketsData : [];

      const activeTickets = tickets.filter((t: any) => t.status !== 'completed' && t.status !== 'treated');

      setStats({
        totalUsers: users.length,
        totalHospitals: hospitals.length,
        activeTickets: activeTickets.length,
        avgWaitTime: tickets.length > 0
          ? Math.round(tickets.reduce((sum: number, t: any) => sum + (t.estimated_wait_minutes || 0), 0) / tickets.length)
          : 0,
      });

      const statusCount = tickets.reduce((acc: any, ticket: any) => {
        acc[ticket.status] = (acc[ticket.status] || 0) + 1;
        return acc;
      }, {});
      const statusLabels: Record<string, string> = {
        waiting: 'En attente', in_triage: 'Triage', triaged: 'Trié',
        in_progress: 'En cours', treated: 'Traité', completed: 'Terminé',
      };
      setTicketsByStatus(
        Object.entries(statusCount).map(([key, value]) => ({
          name: statusLabels[key] || key,
          value,
        }))
      );

      const prioCount = tickets.reduce((acc: any, ticket: any) => {
        const p = ticket.priority_level || ticket.priority || 5;
        acc[p] = (acc[p] || 0) + 1;
        return acc;
      }, {});
      setTicketsByPriority(
        Object.entries(prioCount).map(([key, value]) => ({
          name: priorityLabels[Number(key)] || `P${key}`,
          value,
          priority: Number(key),
        }))
      );

      setRecentTickets(tickets.slice(0, 6));
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      icon: Users, label: 'Utilisateurs', value: stats.totalUsers,
      gradient: 'from-indigo-500 to-purple-500', change: '+12%',
    },
    {
      icon: Building2, label: 'Hôpitaux', value: stats.totalHospitals,
      gradient: 'from-emerald-500 to-teal-500', change: '+2',
    },
    {
      icon: Zap, label: 'Tickets actifs', value: stats.activeTickets,
      gradient: 'from-amber-500 to-orange-500', change: 'live',
    },
    {
      icon: Clock, label: 'Attente moy.', value: `${stats.avgWaitTime || '—'}m`,
      gradient: 'from-rose-500 to-pink-500', change: '-5min',
    },
  ];

  const getStatusColor = (status: string) => {
    if (status === 'waiting') return 'bg-warning-100 text-warning-700';
    if (status === 'in_progress' || status === 'in_triage') return 'bg-primary-100 text-primary-700';
    if (status === 'treated' || status === 'completed') return 'bg-success-100 text-success-700';
    return 'bg-gray-100 text-gray-700';
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <div className="text-center space-y-4 animate-pulse-soft">
          <div className="w-12 h-12 mx-auto border-2 border-primary-200 border-t-primary-600 rounded-full animate-spin" />
          <p className="text-sm text-gray-400">Chargement du dashboard…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Dashboard</h1>
          <p className="text-gray-400 text-sm mt-0.5">Vue d'ensemble de l'activité en temps réel</p>
        </div>
        <div className="flex items-center gap-2 px-3 py-1.5 bg-success-50 text-success-700 rounded-full text-xs font-medium">
          <span className="w-2 h-2 bg-success-500 rounded-full animate-pulse" />
          Système actif
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return (
            <div
              key={index}
              className={`stat-card bg-gradient-to-br ${card.gradient} animate-slide-up stagger-${index + 1}`}
            >
              <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 rounded-full -translate-y-6 translate-x-6" />
              <div className="relative">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center backdrop-blur-sm">
                    <Icon size={20} />
                  </div>
                  <span className="text-xs bg-white/20 px-2 py-0.5 rounded-lg backdrop-blur-sm font-medium">
                    {card.change}
                  </span>
                </div>
                <p className="text-white/70 text-xs font-medium mb-0.5">{card.label}</p>
                <p className="text-3xl font-bold tracking-tight">{card.value}</p>
              </div>
            </div>
          );
        })}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Priority Distribution */}
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-semibold text-gray-900">Distribution par priorité</h3>
              <p className="text-xs text-gray-400 mt-0.5">Échelle de triage québécoise (ETG)</p>
            </div>
          </div>
          {ticketsByPriority.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={ticketsByPriority} barSize={32}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{
                    background: '#fff', borderRadius: 12, border: '1px solid #e2e8f0',
                    boxShadow: '0 4px 16px rgba(0,0,0,0.08)', fontSize: 12,
                  }}
                />
                <Bar dataKey="value" radius={[8, 8, 0, 0]}>
                  {ticketsByPriority.map((entry, i) => (
                    <Cell key={i} fill={['#ef4444', '#f97316', '#eab308', '#3b82f6', '#22c55e'][entry.priority - 1] || '#94a3b8'} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[260px] flex items-center justify-center text-gray-300 text-sm">
              Aucune donnée disponible
            </div>
          )}
        </div>

        {/* Status Pie */}
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-semibold text-gray-900">Tickets par statut</h3>
              <p className="text-xs text-gray-400 mt-0.5">Répartition actuelle</p>
            </div>
          </div>
          {ticketsByStatus.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie
                  data={ticketsByStatus}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={95}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {ticketsByStatus.map((_, index) => (
                    <Cell key={index} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    background: '#fff', borderRadius: 12, border: '1px solid #e2e8f0',
                    boxShadow: '0 4px 16px rgba(0,0,0,0.08)', fontSize: 12,
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[260px] flex items-center justify-center text-gray-300 text-sm">
              Aucune donnée disponible
            </div>
          )}
          {/* Legend */}
          <div className="flex flex-wrap gap-4 justify-center mt-2">
            {ticketsByStatus.map((entry, i) => (
              <div key={i} className="flex items-center gap-1.5 text-xs text-gray-500">
                <span className="w-2.5 h-2.5 rounded-full" style={{ background: COLORS[i % COLORS.length] }} />
                {entry.name}: {entry.value as number}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recent activity */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="font-semibold text-gray-900">Activité récente</h3>
            <p className="text-xs text-gray-400 mt-0.5">Derniers tickets enregistrés</p>
          </div>
          <button className="text-xs text-primary-600 hover:text-primary-700 font-medium flex items-center gap-1">
            Voir tout <ArrowUpRight size={12} />
          </button>
        </div>
        <div className="space-y-3">
          {recentTickets.map((ticket, index) => (
            <div
              key={ticket.id || index}
              className="flex items-center justify-between p-3.5 bg-gray-50/50 rounded-xl border border-gray-100/50 hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-xs font-bold ${priorityColors[ticket.priority_level || 5] || 'bg-gray-100 text-gray-700'
                  }`}>
                  P{ticket.priority_level || '?'}
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {ticket.patient_prenom} {ticket.patient_nom}
                  </p>
                  <p className="text-xs text-gray-400">
                    {ticket.created_at ? new Date(ticket.created_at).toLocaleDateString('fr-CA', {
                      day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit',
                    }) : ''}
                  </p>
                </div>
              </div>
              <span className={`badge ${getStatusColor(ticket.status)}`}>
                {ticket.status === 'waiting' ? 'En attente' :
                  ticket.status === 'in_progress' ? 'En cours' :
                    ticket.status === 'treated' ? 'Traité' :
                      ticket.status === 'completed' ? 'Terminé' : ticket.status}
              </span>
            </div>
          ))}
          {recentTickets.length === 0 && (
            <div className="text-center py-8 text-gray-300">
              <Activity size={32} className="mx-auto mb-2 opacity-50" />
              <p className="text-sm">Aucun ticket récent</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
