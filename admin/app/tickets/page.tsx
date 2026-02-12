'use client';

import { useState, useEffect } from 'react';
import { getTickets, getHospitals } from '@/lib/api';
import {
  Search, Clock, CheckCircle, AlertCircle, MapPin, Zap, Activity,
  AlertTriangle, Timer,
} from 'lucide-react';

interface Ticket {
  id: string;
  code?: string;
  patient_id: string;
  hospital_id: string;
  status: string;
  priority_level: number;
  validated_priority?: number;
  patient_nom?: string;
  patient_prenom?: string;
  patient_name?: string;
  queue_position?: number;
  estimated_wait_minutes?: number;
  created_at: string;
}

interface Hospital {
  id: string;
  name: string;
}

const statusConfig: Record<string, { label: string; color: string; icon: any }> = {
  waiting: { label: 'En attente', color: 'bg-amber-50 text-amber-700 border-amber-200', icon: Clock },
  in_triage: { label: 'Triage', color: 'bg-purple-50 text-purple-700 border-purple-200', icon: Activity },
  triaged: { label: 'Trié', color: 'bg-indigo-50 text-indigo-700 border-indigo-200', icon: AlertCircle },
  in_progress: { label: 'En cours', color: 'bg-blue-50 text-blue-700 border-blue-200', icon: Zap },
  treated: { label: 'Traité', color: 'bg-emerald-50 text-emerald-700 border-emerald-200', icon: CheckCircle },
  completed: { label: 'Terminé', color: 'bg-gray-50 text-gray-500 border-gray-200', icon: CheckCircle },
};

const priorityConfig: Record<number, { label: string; color: string; dot: string }> = {
  1: { label: 'P1 — Réanimation', color: 'bg-red-50 text-red-700 border-red-200', dot: 'bg-red-500' },
  2: { label: 'P2 — Très urgent', color: 'bg-orange-50 text-orange-700 border-orange-200', dot: 'bg-orange-500' },
  3: { label: 'P3 — Urgent', color: 'bg-yellow-50 text-yellow-700 border-yellow-200', dot: 'bg-yellow-500' },
  4: { label: 'P4 — Moins urgent', color: 'bg-blue-50 text-blue-700 border-blue-200', dot: 'bg-blue-500' },
  5: { label: 'P5 — Non urgent', color: 'bg-green-50 text-green-700 border-green-200', dot: 'bg-green-500' },
};

export default function TicketsPage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [hospitals, setHospitals] = useState<Hospital[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [priorityFilter, setPriorityFilter] = useState('all');

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      const [ticketsData, hospitalsData] = await Promise.all([
        getTickets().catch(() => []),
        getHospitals().catch(() => []),
      ]);
      setTickets(Array.isArray(ticketsData) ? ticketsData : []);
      setHospitals(Array.isArray(hospitalsData) ? hospitalsData : []);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getHospitalName = (id: string) => hospitals.find(h => h.id === id)?.name || '—';

  const getPatientName = (ticket: Ticket) =>
    ticket.patient_prenom && ticket.patient_nom
      ? `${ticket.patient_prenom} ${ticket.patient_nom}`
      : ticket.patient_name || 'Anonyme';

  const getWaitTime = (createdAt: string) => {
    const diff = Math.floor((Date.now() - new Date(createdAt).getTime()) / 60000);
    if (diff < 60) return `${diff}m`;
    return `${Math.floor(diff / 60)}h${diff % 60}m`;
  };

  const filteredTickets = tickets.filter(ticket => {
    const name = getPatientName(ticket).toLowerCase();
    const matchesSearch = name.includes(searchTerm.toLowerCase()) || (ticket.code || '').toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || ticket.status === statusFilter;
    const matchesPriority = priorityFilter === 'all' || String(ticket.priority_level) === priorityFilter;
    return matchesSearch && matchesStatus && matchesPriority;
  });

  const stats = {
    total: tickets.length,
    waiting: tickets.filter(t => t.status === 'waiting').length,
    active: tickets.filter(t => ['in_triage', 'triaged', 'in_progress'].includes(t.status)).length,
    done: tickets.filter(t => ['treated', 'completed'].includes(t.status)).length,
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <div className="w-10 h-10 border-2 border-primary-200 border-t-primary-600 rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Tickets</h1>
        <p className="text-gray-400 text-sm mt-0.5">Gestion de la file d'attente</p>
      </div>

      {/* Stat mini-cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total', value: stats.total, icon: Activity, bg: 'from-gray-500 to-slate-500' },
          { label: 'En attente', value: stats.waiting, icon: Clock, bg: 'from-amber-500 to-orange-500' },
          { label: 'En cours', value: stats.active, icon: Zap, bg: 'from-indigo-500 to-blue-500' },
          { label: 'Terminés', value: stats.done, icon: CheckCircle, bg: 'from-emerald-500 to-green-500' },
        ].map((s, i) => {
          const Icon = s.icon;
          return (
            <div key={i} className={`stat-card bg-gradient-to-br ${s.bg} animate-slide-up stagger-${i + 1}`}>
              <div className="absolute top-0 right-0 w-16 h-16 bg-white/10 rounded-full -translate-y-4 translate-x-4" />
              <div className="relative flex items-center justify-between">
                <div>
                  <p className="text-white/60 text-[11px] font-medium">{s.label}</p>
                  <p className="text-2xl font-bold mt-0.5">{s.value}</p>
                </div>
                <div className="w-9 h-9 bg-white/15 rounded-xl flex items-center justify-center backdrop-blur-sm">
                  <Icon size={17} />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[220px]">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-300" size={18} />
          <input
            type="text"
            placeholder="Rechercher par patient ou code…"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input pl-11 !rounded-2xl !border-gray-100 !bg-white shadow-glass-sm"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="input !w-auto !rounded-2xl !border-gray-100"
        >
          <option value="all">Tous les statuts</option>
          {Object.entries(statusConfig).map(([key, cfg]) => (
            <option key={key} value={key}>{cfg.label}</option>
          ))}
        </select>
        <select
          value={priorityFilter}
          onChange={(e) => setPriorityFilter(e.target.value)}
          className="input !w-auto !rounded-2xl !border-gray-100"
        >
          <option value="all">Toutes priorités</option>
          {Object.entries(priorityConfig).map(([key, cfg]) => (
            <option key={key} value={key}>{cfg.label}</option>
          ))}
        </select>
      </div>

      {/* Tickets Table */}
      <div className="bg-white rounded-2xl shadow-glass-sm border border-gray-100/80 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="table-header">Patient</th>
                <th className="table-header">Priorité</th>
                <th className="table-header">Statut</th>
                <th className="table-header">Hôpital</th>
                <th className="table-header">Position</th>
                <th className="table-header">Attente</th>
                <th className="table-header">Créé</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filteredTickets.map((ticket) => {
                const prio = ticket.validated_priority || ticket.priority_level || 5;
                const prioConf = priorityConfig[prio] || priorityConfig[5];
                const statusConf = statusConfig[ticket.status] || statusConfig.waiting;
                const StatusIcon = statusConf.icon;

                return (
                  <tr key={ticket.id} className="hover:bg-gray-50/50 transition-colors">
                    <td className="table-cell">
                      <div className="flex items-center gap-3">
                        <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-xs font-bold ${prio <= 2 ? 'bg-red-100 text-red-700' :
                            prio === 3 ? 'bg-yellow-100 text-yellow-700' :
                              'bg-blue-100 text-blue-700'
                          }`}>
                          P{prio}
                        </div>
                        <div>
                          <p className="font-medium text-gray-900 text-sm">{getPatientName(ticket)}</p>
                          {ticket.code && <p className="text-gray-300 text-[11px] font-mono">#{ticket.code}</p>}
                        </div>
                      </div>
                    </td>
                    <td className="table-cell">
                      <span className={`badge ${prioConf.color}`}>
                        <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${prioConf.dot}`} />
                        {prioConf.label}
                      </span>
                    </td>
                    <td className="table-cell">
                      <span className={`badge ${statusConf.color}`}>
                        <StatusIcon size={12} className="mr-1" />
                        {statusConf.label}
                      </span>
                    </td>
                    <td className="table-cell">
                      <div className="flex items-center gap-1.5 text-xs text-gray-500">
                        <MapPin size={13} className="text-gray-300" />
                        {getHospitalName(ticket.hospital_id)}
                      </div>
                    </td>
                    <td className="table-cell text-center">
                      {ticket.queue_position ? (
                        <span className="inline-flex items-center justify-center w-7 h-7 bg-gray-100 text-gray-700 rounded-lg text-xs font-semibold">
                          {ticket.queue_position}
                        </span>
                      ) : (
                        <span className="text-gray-300">—</span>
                      )}
                    </td>
                    <td className="table-cell">
                      <div className="flex items-center gap-1.5 text-xs text-gray-500">
                        <Timer size={13} className="text-gray-300" />
                        {ticket.estimated_wait_minutes
                          ? `~${ticket.estimated_wait_minutes}m`
                          : getWaitTime(ticket.created_at)
                        }
                      </div>
                    </td>
                    <td className="table-cell text-gray-400 text-xs">
                      {ticket.created_at ? new Date(ticket.created_at).toLocaleDateString('fr-CA', {
                        day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit',
                      }) : '—'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        {filteredTickets.length === 0 && (
          <div className="text-center py-16 text-gray-300">
            <AlertTriangle size={32} className="mx-auto mb-2 opacity-40" />
            <p className="text-sm">Aucun ticket trouvé</p>
          </div>
        )}
      </div>
    </div>
  );
}
