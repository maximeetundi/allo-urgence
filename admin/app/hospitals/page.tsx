'use client';

import { useState, useEffect } from 'react';
import { getHospitals, createHospital, updateHospital, deleteHospital } from '@/lib/api';
import { Plus, Trash2, Edit2, MapPin, Users, Search } from 'lucide-react';

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
  const [formData, setFormData] = useState({
    name: '',
    address: '',
    latitude: '',
    longitude: '',
    capacity: '',
  });

  useEffect(() => {
    loadHospitals();
  }, []);

  const loadHospitals = async () => {
    try {
      const data = await getHospitals();
      setHospitals(data);
    } catch (error) {
      console.error('Error loading hospitals:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
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
    } catch (error) {
      console.error('Error saving hospital:', error);
      alert('Erreur lors de la sauvegarde');
    }
  };

  const handleEdit = (hospital: Hospital) => {
    setEditingHospital(hospital);
    setFormData({
      name: hospital.name,
      address: hospital.address,
      latitude: hospital.latitude.toString(),
      longitude: hospital.longitude.toString(),
      capacity: hospital.capacity.toString(),
    });
    setShowModal(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cet hôpital ?')) return;
    try {
      await deleteHospital(id);
      loadHospitals();
    } catch (error) {
      console.error('Error deleting hospital:', error);
      alert('Erreur lors de la suppression');
    }
  };

  const filteredHospitals = hospitals.filter(h =>
    h.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    h.address.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Hôpitaux</h1>
          <p className="text-gray-500">Gestion des hôpitaux partenaires</p>
        </div>
        <button
          onClick={() => {
            setEditingHospital(null);
            setFormData({ name: '', address: '', latitude: '', longitude: '', capacity: '' });
            setShowModal(true);
          }}
          className="btn-primary flex items-center gap-2"
        >
          <Plus size={20} />
          Nouvel hôpital
        </button>
      </div>

      {/* Search */}
      <div className="card">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Rechercher un hôpital..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input pl-10"
          />
        </div>
      </div>

      {/* Hospitals Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredHospitals.map((hospital) => (
          <div key={hospital.id} className="card">
            <div className="flex items-start justify-between">
              <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center">
                <MapPin className="text-primary-600" size={24} />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => handleEdit(hospital)}
                  className="p-2 text-gray-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors"
                >
                  <Edit2 size={18} />
                </button>
                <button
                  onClick={() => handleDelete(hospital.id)}
                  className="p-2 text-gray-400 hover:text-danger-600 hover:bg-danger-50 rounded-lg transition-colors"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            </div>

            <h3 className="font-semibold text-lg mt-4">{hospital.name}</h3>
            <p className="text-gray-500 text-sm mt-1">{hospital.address}</p>

            <div className="flex items-center gap-4 mt-4 pt-4 border-t border-gray-100">
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Users size={16} />
                <span>Capacité: {hospital.capacity}</span>
              </div>
            </div>

            <div className="mt-3 text-xs text-gray-400">
              {hospital.latitude.toFixed(4)}, {hospital.longitude.toFixed(4)}
            </div>
          </div>
        ))}
      </div>

      {filteredHospitals.length === 0 && (
        <div className="text-center py-12 text-gray-500">
          Aucun hôpital trouvé
        </div>
      )}

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="card w-full max-w-md">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold">
                {editingHospital ? 'Modifier' : 'Nouvel'} hôpital
              </h2>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Nom *
                </label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="input"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Adresse *
                </label>
                <input
                  type="text"
                  required
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="input"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Latitude *
                  </label>
                  <input
                    type="number"
                    step="any"
                    required
                    value={formData.latitude}
                    onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                    className="input"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Longitude *
                  </label>
                  <input
                    type="number"
                    step="any"
                    required
                    value={formData.longitude}
                    onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                    className="input"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Capacité *
                </label>
                <input
                  type="number"
                  required
                  value={formData.capacity}
                  onChange={(e) => setFormData({ ...formData, capacity: e.target.value })}
                  className="input"
                />
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="btn-secondary flex-1"
                >
                  Annuler
                </button>
                <button type="submit" className="btn-primary flex-1">
                  {editingHospital ? 'Mettre à jour' : 'Créer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
