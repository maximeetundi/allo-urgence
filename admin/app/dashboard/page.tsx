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
} from 'recharts';

const COLORS = ['#3b82f6', '#22c55e', '#f59e0b', '#ef4444'];

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
  const [recentTickets, setRecentTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      const [users, hospitals, tickets] = await Promise.all([
        getUsers(),
        getHospitals(),
        getTickets(),
      ]);

      const activeTickets = tickets.filter((t: any) => t.status !== 'completed');
      
      setStats({
        totalUsers: users.length || 0,
        totalHospitals: hospitals.length || 0,
        activeTickets: activeTickets.length || 0,
        avgWaitTime: 45,
      });

      // Group tickets by status
      const statusCount = tickets.reduce((acc: any, ticket: any) => {
        acc[ticket.status] = (acc[ticket.status] || 0) + 1;
        return acc;
      }, {});

      setTicketsByStatus(
        Object.entries(statusCount).map(([name, value]) => ({
          name: name === 'waiting' ? 'En attente' : 
                name === 'in_progress' ? 'En cours' :
                name === 'completed' ? 'Terminé' : name,
          value,
        }))
      );

      setRecentTickets(tickets.slice(0, 5));
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    { icon: Users, label: 'Utilisateurs', value: stats.totalUsers, color: 'bg-primary-500' },
    { icon: Building2, label: 'Hôpitaux', value: stats.totalHospitals, color: 'bg-success-500' },
    { icon: Ticket, label: 'Tickets actifs', value: stats.activeTickets, color: 'bg-warning-500' },
    { icon: Clock, label: 'Temps moyen d\'attente', value: `${stats.avgWaitTime}min`, color: 'bg-danger-500' },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500">Vue d'ensemble de l'activité</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return (
            <div key={index} className="card flex items-center gap-4">
              <div className={`${card.color} p-3 rounded-lg text-white`}>
                <Icon size={24} />
              </div>
              <div>
                <p className="text-sm text-gray-500">{card.label}</p>
                <p className="text-2xl font-bold text-gray-900">{card.value}</p>
              </div>
            </div>
          );
        })}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <h3 className="text-lg font-semibold mb-4">Tickets par statut</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={ticketsByStatus}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {ticketsByStatus.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <h3 className="text-lg font-semibold mb-4">Activité récente</h3>
          <div className="space-y-3">
            {recentTickets.map((ticket, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="font-medium text-gray-900">Ticket #{ticket.code}</p>
                  <p className="text-sm text-gray-500">{ticket.patient_name}</p>
                </div>
                <span className={`px-2 py-1 text-xs rounded-full ${
                  ticket.status === 'waiting' ? 'bg-warning-100 text-warning-700' :
                  ticket.status === 'in_progress' ? 'bg-primary-100 text-primary-700' :
                  'bg-success-100 text-success-700'
                }`}>
                  {ticket.status}
                </span>
              </div>
            ))}
            {recentTickets.length === 0 && (
              <p className="text-gray-500 text-center py-4">Aucun ticket récent</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
