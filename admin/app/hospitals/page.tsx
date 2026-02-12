'use client';

import { useState, useEffect } from 'react';
import { getHospitals, createHospital, updateHospital, deleteHospital } from '@/lib/api';
import {
  Plus, Trash2, Edit2, MapPin, Users, Search, X, Building2, Activity,
} from 'lucide-react';

interface Hospital {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  capacity: number;
  created_at: string;
}

export default function HospitalsPage() {
  const [hospitals, setHospitals] = useState<Hospital[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingHospital, setEditingHospital] = useState<Hospital | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState({
    name: '', address: '', latitude: '', longitude: '', capacity: '',
  });

  useEffect(() => { loadHospitals(); }, []);

  const loadHospitals = async () => {
    try {
      const data = await getHospitals();
      setHospitals(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Error loading hospitals:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    const data = {
      name: formData.name,
      address: formData.address,
      latitude: parseFloat(formData.latitude),
      longitude: parseFloat(formData.longitude),
      capacity: parseInt(formData.capacity),
    };
    try {
      if (editingHospital) {
        await updateHospital(editingHospital.id, data);
      } else {
        await createHospital(data);
      }
      setShowModal(false);
      setEditingHospital(null);
      setFormData({ name: '', address: '', latitude: '', longitude: '', capacity: '' });
      loadHospitals();
    } catch (error: any) {
      alert(error.message || 'Erreur lors de la sauvegarde');
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (hospital: Hospital) => {
    setEditingHospital(hospital);
    setFormData({
      name: hospital.name,
      address: hospital.address,
      latitude: hospital.latitude?.toString() || '',
      longitude: hospital.longitude?.toString() || '',
      capacity: hospital.capacity?.toString() || '',
    });
    setShowModal(true);
  };

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`Supprimer l'hôpital ${name} ?`)) return;
    try {
      await deleteHospital(id);
      loadHospitals();
    } catch (error: any) {
      alert(error.message || 'Erreur lors de la suppression');
    }
  };

  const openCreate = () => {
    setEditingHospital(null);
    setFormData({ name: '', address: '', latitude: '', longitude: '', capacity: '' });
    setShowModal(true);
  };

  const filteredHospitals = hospitals.filter(h =>
    h.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    h.address?.toLowerCase().includes(searchTerm.toLowerCase())
  );

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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Hôpitaux</h1>
          <p className="text-gray-400 text-sm mt-0.5">{hospitals.length} établissements partenaires</p>
        </div>
        <button onClick={openCreate} className="btn-primary flex items-center gap-2 text-sm">
          <Plus size={18} />
          Nouvel hôpital
        </button>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-300" size={18} />
        <input
          type="text"
          placeholder="Rechercher un hôpital…"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="input pl-11 !rounded-2xl !border-gray-100 !bg-white shadow-glass-sm"
        />
      </div>

      {/* Hospital Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {filteredHospitals.map((hospital, i) => (
          <div
            key={hospital.id}
            className={`card group animate-slide-up stagger-${Math.min(i + 1, 5)}`}
          >
            <div className="flex items-start justify-between">
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary-100 to-indigo-100 flex items-center justify-center">
                <Building2 className="text-primary-600" size={22} />
              </div>
              <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  onClick={() => handleEdit(hospital)}
                  className="p-2 text-gray-300 hover:text-primary-600 hover:bg-primary-50 rounded-xl transition-all"
                >
                  <Edit2 size={15} />
                </button>
                <button
                  onClick={() => handleDelete(hospital.id, hospital.name)}
                  className="p-2 text-gray-300 hover:text-danger-600 hover:bg-danger-50 rounded-xl transition-all"
                >
                  <Trash2 size={15} />
                </button>
              </div>
            </div>

            <h3 className="font-semibold text-gray-900 mt-4 text-[15px]">{hospital.name}</h3>
            <p className="text-gray-400 text-xs mt-1 flex items-center gap-1">
              <MapPin size={12} />
              {hospital.address || 'Adresse non renseignée'}
            </p>

            <div className="mt-5 pt-4 border-t border-gray-50 flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs text-gray-500">
                <Users size={14} className="text-gray-300" />
                <span>Capacité: <strong className="text-gray-700">{hospital.capacity || '—'}</strong></span>
              </div>
              {/* Capacity indicator */}
              <div className="w-16 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-primary-400 to-indigo-400 rounded-full transition-all duration-500"
                  style={{ width: `${Math.min((hospital.capacity || 0) / 5, 100)}%` }}
                />
              </div>
            </div>

            {hospital.latitude && hospital.longitude && (
              <div className="mt-2 text-[10px] text-gray-300 font-mono">
                {Number(hospital.latitude).toFixed(4)}, {Number(hospital.longitude).toFixed(4)}
              </div>
            )}
          </div>
        ))}
      </div>

      {filteredHospitals.length === 0 && (
        <div className="text-center py-16 text-gray-300">
          <Building2 size={40} className="mx-auto mb-3 opacity-40" />
          <p className="text-sm">Aucun hôpital trouvé</p>
        </div>
      )}

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-xl flex items-center justify-center">
                  <Building2 size={18} className="text-white" />
                </div>
                <h2 className="text-lg font-bold text-gray-900">
                  {editingHospital ? 'Modifier' : 'Nouvel'} hôpital
                </h2>
              </div>
              <button onClick={() => setShowModal(false)} className="p-2 hover:bg-gray-100 rounded-xl transition-colors">
                <X size={18} className="text-gray-400" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Nom</label>
                <input type="text" required value={formData.name}
                  onChange={e => setFormData({ ...formData, name: e.target.value })} className="input" />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Adresse</label>
                <input type="text" required value={formData.address}
                  onChange={e => setFormData({ ...formData, address: e.target.value })} className="input" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Latitude</label>
                  <input type="number" step="any" required value={formData.latitude}
                    onChange={e => setFormData({ ...formData, latitude: e.target.value })} className="input" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Longitude</label>
                  <input type="number" step="any" required value={formData.longitude}
                    onChange={e => setFormData({ ...formData, longitude: e.target.value })} className="input" />
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Capacité</label>
                <input type="number" required value={formData.capacity}
                  onChange={e => setFormData({ ...formData, capacity: e.target.value })} className="input" />
              </div>

              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setShowModal(false)} className="btn-secondary flex-1">
                  Annuler
                </button>
                <button type="submit" disabled={saving} className="btn-primary flex-1 flex items-center justify-center gap-2">
                  {saving ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : editingHospital ? 'Mettre à jour' : 'Créer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
