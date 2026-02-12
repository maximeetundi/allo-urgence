'use client';

import { useState, useEffect } from 'react';
import { getTickets, getHospitals } from '@/lib/api';
import { Search, Filter, Clock, CheckCircle, AlertCircle, MapPin } from 'lucide-react';

interface Ticket {
  id: string;
  code: string;
  patient_id: string;
  hospital_id: string;
  status: 'waiting' | 'in_progress' | 'completed';
  priority: number;
  patient_name: string;
  patient_phone: string;
  created_at: string;
  updated_at: string;
}

interface Hospital {
  id: string;
  name: string;
}

const statusLabels: Record<string, string> = {
  waiting: 'En attente',
  in_progress: 'En cours',
  completed: 'Terminé',
};

const statusColors: Record<string, string> = {
  waiting: 'bg-warning-100 text-warning-700 border-warning-200',
  in_progress: 'bg-primary-100 text-primary-700 border-primary-200',
  completed: 'bg-success-100 text-success-700 border-success-200',
};

const priorityLabels: Record<number, { label: string; color: string }> = {
  1: { label: 'Non urgent', color: 'bg-gray-100 text-gray-600' },
  2: { label: 'Peu urgent', color: 'bg-blue-100 text-blue-600' },
  3: { label: 'Urgent', color: 'bg-warning-100 text-warning-600' },
  4: { label: 'Très urgent', color: 'bg-orange-100 text-orange-600' },
  5: { label: 'Critique', color: 'bg-danger-100 text-danger-600' },
};

export default function TicketsPage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [hospitals, setHospitals] = useState<Hospital[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [ticketsData, hospitalsData] = await Promise.all([
        getTickets(),
        getHospitals(),
      ]);
      setTickets(ticketsData);
      setHospitals(hospitalsData);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getHospitalName = (id: string) => {
    const hospital = hospitals.find(h => h.id === id);
    return hospital?.name || 'Hôpital inconnu';
  };

  const getWaitTime = (createdAt: string) => {
    const created = new Date(createdAt);
    const now = new Date();
    const diff = Math.floor((now.getTime() - created.getTime()) / 1000 / 60); // minutes
    if (diff < 60) return `${diff} min`;
    const hours = Math.floor(diff / 60);
    const mins = diff % 60;
    return `${hours}h ${mins}min`;
  };

  const filteredTickets = tickets.filter(ticket => {
    const matchesSearch = 
      ticket.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.patient_name?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || ticket.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const stats = {
    waiting: tickets.filter(t => t.status === 'waiting').length,
    in_progress: tickets.filter(t => t.status === 'in_progress').length,
    completed: tickets.filter(t => t.status === 'completed').length,
    total: tickets.length,
  };

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
        <h1 className="text-2xl font-bold text-gray-900">Tickets</h1>
        <p className="text-gray-500">Gestion de la file d'attente</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="card flex items-center justify-between">
          <div>
            <p className="text-sm text-gray-500">Total</p>
            <p className="text-2xl font-bold">{stats.total}</p>
          </div>
          <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
            <AlertCircle className="text-gray-600" size={20} />
          </div>
        </div>
        <div className="card flex items-center justify-between border-l-4 border-l-warning-500">
          <div>
            <p className="text-sm text-gray-500">En attente</p>
            <p className="text-2xl font-bold text-warning-600">{stats.waiting}</p>
          </div>
          <div className="w-10 h-10 bg-warning-100 rounded-lg flex items-center justify-center">
            <Clock className="text-warning-600" size={20} />
          </div>
        </div>
        <div className="card flex items-center justify-between border-l-4 border-l-primary-500">
          <div>
            <p className="text-sm text-gray-500">En cours</p>
            <p className="text-2xl font-bold text-primary-600">{stats.in_progress}</p>
          </div>
          <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
            <AlertCircle className="text-primary-600" size={20} />
          </div>
        </div>
        <div className="card flex items-center justify-between border-l-4 border-l-success-500">
          <div>
            <p className="text-sm text-gray-500">Terminés</p>
            <p className="text-2xl font-bold text-success-600">{stats.completed}</p>
          </div>
          <div className="w-10 h-10 bg-success-100 rounded-lg flex items-center justify-center">
            <CheckCircle className="text-success-600" size={20} />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="card flex flex-wrap items-center gap-4">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Rechercher un ticket..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input pl-10"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="input w-auto"
        >
          <option value="all">Tous les statuts</option>
          <option value="waiting">En attente</option>
          <option value="in_progress">En cours</option>
          <option value="completed">Terminé</option>
        </select>
      </div>

      {/* Tickets Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="table-header">Code</th>
                <th className="table-header">Patient</th>
                <th className="table-header">Hôpital</th>
                <th className="table-header">Priorité</th>
                <th className="table-header">Statut</th>
                <th className="table-header">Attente</th>
                <th className="table-header">Créé le</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredTickets.map((ticket) => (
                <tr key={ticket.id} className="hover:bg-gray-50">
                  <td className="table-cell font-mono font-medium">#{ticket.code}</td>
                  <td className="table-cell">
                    <div>
                      <p className="font-medium">{ticket.patient_name || 'Anonyme'}</p>
                      <p className="text-sm text-gray-500">{ticket.patient_phone}</p>
                    </div>
                  </td>
                  <td className="table-cell">
                    <div className="flex items-center gap-2">
                      <MapPin size={16} className="text-gray-400" />
                      <span className="text-sm">{getHospitalName(ticket.hospital_id)}</span>
                    </div>
                  </td>
                  <td className="table-cell">
                    <span className={`px-2 py-1 text-xs rounded-full ${priorityLabels[ticket.priority]?.color || priorityLabels[1].color}`}>
                      {priorityLabels[ticket.priority]?.label || 'Non urgent'}
                    </span>
                  </td>
                  <td className="table-cell">
                    <span className={`px-3 py-1 text-xs rounded-full border ${statusColors[ticket.status]}`}>
                      {statusLabels[ticket.status]}
                    </span>
                  </td>
                  <td className="table-cell">
                    <div className="flex items-center gap-2">
                      <Clock size={16} className="text-gray-400" />
                      <span>{getWaitTime(ticket.created_at)}</span>
                    </div>
                  </td>
                  <td className="table-cell text-sm text-gray-500">
                    {new Date(ticket.created_at).toLocaleDateString('fr-CA', {
                      day: '2-digit',
                      month: 'short',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filteredTickets.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            Aucun ticket trouvé
          </div>
        )}
      </div>
    </div>
  );
}
