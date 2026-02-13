'use client';

import { useState, useEffect } from 'react';
import { getUsers, createUser, updateUser, deleteUser, getHospitals } from '@/lib/api';
import {
  Plus, Trash2, Edit2, Search, X, UserPlus,
  Shield, Stethoscope, Heart, Users as UsersIcon,
} from 'lucide-react';

interface User {
  id: string;
  email: string;
  nom: string;
  prenom: string;
  role: string;
  telephone?: string;
  hospital_ids?: string[];
  created_at: string;
}

const roleConfig: Record<string, { label: string; color: string; icon: any }> = {
  patient: { label: 'Patient', color: 'bg-gray-50 text-gray-600 border-gray-200', icon: Heart },
  nurse: { label: 'Infirmier(ère)', color: 'bg-indigo-50 text-indigo-700 border-indigo-200', icon: UsersIcon },
  doctor: { label: 'Médecin', color: 'bg-emerald-50 text-emerald-700 border-emerald-200', icon: Stethoscope },
  admin: { label: 'Administrateur', color: 'bg-rose-50 text-rose-700 border-rose-200', icon: Shield },
};

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [saving, setSaving] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [newUser, setNewUser] = useState<{
    email: string; password: string; nom: string; prenom: string; role: string; telephone: string; hospital_ids?: string[]
  }>({
    email: '', password: '', nom: '', prenom: '', role: 'nurse', telephone: '', hospital_ids: []
  });

  const [hospitals, setHospitals] = useState<any[]>([]);

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      const [usersData, hospitalsData] = await Promise.all([getUsers(), getHospitals()]);
      setUsers(Array.isArray(usersData) ? usersData : []);
      setHospitals(Array.isArray(hospitalsData) ? hospitalsData : []);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (editingUser) {
        const updateData = { ...newUser };
        if (!updateData.password) delete (updateData as any).password;
        await updateUser(editingUser.id, updateData);
      } else {
        await createUser(newUser);
      }
      setShowModal(false);
      setEditingUser(null);
      setNewUser({ email: '', password: '', nom: '', prenom: '', role: 'nurse', telephone: '', hospital_ids: [] });
      loadData();
    } catch (error: any) {
      alert(error.message || 'Erreur lors de la sauvegarde');
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (user: User) => {
    setEditingUser(user);
    setNewUser({
      email: user.email,
      password: '', // Leave empty to keep unchanged
      nom: user.nom || '',
      prenom: user.prenom || '',
      role: user.role,
      telephone: user.telephone || '',
      hospital_ids: user.hospital_ids || [],
    });
    setShowModal(true);
  };

  const openCreate = () => {
    setEditingUser(null);
    setNewUser({ email: '', password: '', nom: '', prenom: '', role: 'nurse', telephone: '', hospital_ids: [] });
    setShowModal(true);
  };

  const handleDeleteUser = async (id: string, name: string) => {
    if (!confirm(`Supprimer l'utilisateur ${name} ?`)) return;
    try {
      await deleteUser(id);
      await deleteUser(id);
      loadData();
    } catch (error: any) {
      alert(error.message || 'Erreur lors de la suppression');
    }
  };

  const filteredUsers = users.filter(user => {
    const matchesSearch =
      user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.nom?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.prenom?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesRole = roleFilter === 'all' || user.role === roleFilter;
    return matchesSearch && matchesRole;
  });

  const roleCounts = users.reduce((acc: Record<string, number>, u) => {
    acc[u.role] = (acc[u.role] || 0) + 1;
    return acc;
  }, {});

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
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Utilisateurs</h1>
          <p className="text-gray-400 text-sm mt-0.5">{users.length} utilisateurs enregistrés</p>
        </div>
        <button onClick={openCreate} className="btn-primary flex items-center gap-2 text-sm">
          <Plus size={18} />
          Nouvel utilisateur
        </button>
      </div>

      {/* Role filter chips */}
      <div className="flex gap-2 flex-wrap">
        {[
          { key: 'all', label: 'Tous', count: users.length },
          ...Object.entries(roleConfig).map(([key, cfg]) => ({
            key, label: cfg.label, count: roleCounts[key] || 0,
          })),
        ].map(chip => (
          <button
            key={chip.key}
            onClick={() => setRoleFilter(chip.key)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-medium transition-all duration-200 border ${roleFilter === chip.key
              ? 'bg-primary-50 text-primary-700 border-primary-200 shadow-sm'
              : 'bg-white text-gray-500 border-gray-100 hover:bg-gray-50'
              }`}
          >
            {chip.label}
            <span className="ml-1.5 text-[10px] opacity-60">{chip.count}</span>
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-300" size={18} />
        <input
          type="text"
          placeholder="Rechercher par nom, prénom ou email…"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="input pl-11 !rounded-2xl !border-gray-100 !bg-white shadow-glass-sm"
        />
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-2xl shadow-glass-sm border border-gray-100/80 overflow-hidden">
        <table className="min-w-full">
          <thead>
            <tr className="border-b border-gray-100">
              <th className="table-header">Utilisateur</th>
              <th className="table-header">Rôle</th>
              <th className="table-header">Téléphone</th>
              <th className="table-header">Inscrit le</th>
              <th className="table-header text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filteredUsers.map((user) => {
              const role = roleConfig[user.role] || roleConfig.patient;
              return (
                <tr key={user.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="table-cell">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-primary-100 to-indigo-100 flex items-center justify-center text-xs font-bold text-primary-700">
                        {user.prenom?.[0]}{user.nom?.[0]}
                      </div>
                      <div>
                        <p className="font-medium text-gray-900 text-sm">{user.prenom} {user.nom}</p>
                        <p className="text-gray-400 text-xs">{user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="table-cell">
                    <span className={`badge ${role.color}`}>
                      {role.label}
                    </span>
                  </td>
                  <td className="table-cell text-gray-500">{user.telephone || '—'}</td>
                  <td className="table-cell text-gray-400 text-xs">
                    {user.created_at ? new Date(user.created_at).toLocaleDateString('fr-CA') : '—'}
                  </td>
                  <td className="table-cell text-right">
                    <button
                      onClick={() => handleDeleteUser(user.id, `${user.prenom} ${user.nom}`)}
                      className="p-2 text-gray-300 hover:text-danger-600 hover:bg-danger-50 rounded-xl transition-all"
                    >
                      <Trash2 size={16} />
                    </button>
                    <button
                      onClick={() => handleEdit(user)}
                      className="p-2 text-gray-300 hover:text-primary-600 hover:bg-primary-50 rounded-xl transition-all ml-1"
                    >
                      <Edit2 size={16} />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {filteredUsers.length === 0 && (
          <div className="text-center py-12 text-gray-300">
            <UsersIcon size={32} className="mx-auto mb-2 opacity-50" />
            <p className="text-sm">Aucun utilisateur trouvé</p>
          </div>
        )}
      </div>

      {/* Create Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gradient-to-br from-indigo-500 to-primary-500 rounded-xl flex items-center justify-center">
                  <UserPlus size={18} className="text-white" />
                </div>
                <h2 className="text-lg font-bold text-gray-900">
                  {editingUser ? 'Modifier' : 'Nouvel'} utilisateur
                </h2>
              </div>
              <button onClick={() => setShowModal(false)} className="p-2 hover:bg-gray-100 rounded-xl transition-colors">
                <X size={18} className="text-gray-400" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Prénom</label>
                  <input type="text" required value={newUser.prenom}
                    onChange={e => setNewUser({ ...newUser, prenom: e.target.value })} className="input" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Nom</label>
                  <input type="text" required value={newUser.nom}
                    onChange={e => setNewUser({ ...newUser, nom: e.target.value })} className="input" />
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Email</label>
                <input type="email" required value={newUser.email}
                  onChange={e => setNewUser({ ...newUser, email: e.target.value })} className="input" />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">
                  Mot de passe {editingUser && <span className="text-gray-400 font-normal">(laisser vide pour conserver)</span>}
                </label>
                <input type="password" required={!editingUser} value={newUser.password}
                  onChange={e => setNewUser({ ...newUser, password: e.target.value })} className="input" />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Rôle</label>
                <select value={newUser.role}
                  onChange={e => setNewUser({ ...newUser, role: e.target.value })} className="input">
                  <option value="nurse">Infirmier(ère)</option>
                  <option value="doctor">Médecin</option>
                  <option value="admin">Administrateur</option>
                  <option value="patient">Patient</option>
                </select>
              </div>

              {(newUser.role === 'nurse' || newUser.role === 'doctor') && (
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Hôpitaux assignés</label>
                  <div className="border border-gray-100 rounded-xl p-2 max-h-32 overflow-y-auto bg-gray-50/50">
                    {hospitals.map(hospital => (
                      <label key={hospital.id} className="flex items-center gap-2 p-1.5 hover:bg-white rounded-lg cursor-pointer transition-colors">
                        <input
                          type="checkbox"
                          checked={(newUser.hospital_ids || []).includes(hospital.id)}
                          onChange={e => {
                            const current = newUser.hospital_ids || [];
                            const newIds = e.target.checked
                              ? [...current, hospital.id]
                              : current.filter(id => id !== hospital.id);
                            setNewUser({ ...newUser, hospital_ids: newIds });
                          }}
                          className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                        />
                        <span className="text-sm text-gray-700">{hospital.name}</span>
                      </label>
                    ))}
                    {hospitals.length === 0 && <p className="text-xs text-gray-400 p-1">Aucun hôpital disponible</p>}
                  </div>
                </div>
              )}

              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5 ml-0.5">Téléphone</label>
                <input type="tel" value={newUser.telephone}
                  onChange={e => setNewUser({ ...newUser, telephone: e.target.value })} className="input" />
              </div>

              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setShowModal(false)} className="btn-secondary flex-1">
                  Annuler
                </button>
                <button type="submit" disabled={saving} className="btn-primary flex-1 flex items-center justify-center gap-2">
                  {saving ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> : editingUser ? 'Mettre à jour' : 'Créer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
