'use client';

import { useState, useEffect } from 'react';
import { getUsers, createUser, deleteUser } from '@/lib/api';
import { Plus, Trash2, UserPlus, Search, Filter } from 'lucide-react';

interface User {
  id: string;
  email: string;
  nom: string;
  prenom: string;
  role: string;
  telephone?: string;
  created_at: string;
}

const roleLabels: Record<string, string> = {
  patient: 'Patient',
  nurse: 'Infirmier(ère)',
  doctor: 'Médecin',
  admin: 'Administrateur',
};

const roleColors: Record<string, string> = {
  patient: 'bg-gray-100 text-gray-700',
  nurse: 'bg-primary-100 text-primary-700',
  doctor: 'bg-success-100 text-success-700',
  admin: 'bg-danger-100 text-danger-700',
};

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [newUser, setNewUser] = useState({
    email: '',
    password: '',
    nom: '',
    prenom: '',
    role: 'nurse',
    telephone: '',
  });

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      const data = await getUsers();
      setUsers(data);
    } catch (error) {
      console.error('Error loading users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await createUser(newUser);
      setShowModal(false);
      setNewUser({
        email: '',
        password: '',
        nom: '',
        prenom: '',
        role: 'nurse',
        telephone: '',
      });
      loadUsers();
    } catch (error) {
      console.error('Error creating user:', error);
      alert('Erreur lors de la création de l\'utilisateur');
    }
  };

  const handleDeleteUser = async (id: string) => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cet utilisateur ?')) return;
    try {
      await deleteUser(id);
      loadUsers();
    } catch (error) {
      console.error('Error deleting user:', error);
      alert('Erreur lors de la suppression');
    }
  };

  const filteredUsers = users.filter(user =>
    user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.nom.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.prenom.toLowerCase().includes(searchTerm.toLowerCase())
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
          <h1 className="text-2xl font-bold text-gray-900">Utilisateurs</h1>
          <p className="text-gray-500">Gestion des utilisateurs du système</p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="btn-primary flex items-center gap-2"
        >
          <Plus size={20} />
          Nouvel utilisateur
        </button>
      </div>

      {/* Search */}
      <div className="card flex items-center gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Rechercher un utilisateur..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input pl-10"
          />
        </div>
        <button className="btn-secondary flex items-center gap-2">
          <Filter size={20} />
          Filtrer
        </button>
      </div>

      {/* Users Table */}
      <div className="card overflow-hidden">
        <table className="min-w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="table-header">Utilisateur</th>
              <th className="table-header">Rôle</th>
              <th className="table-header">Téléphone</th>
              <th className="table-header">Date de création</th>
              <th className="table-header">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {filteredUsers.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="table-cell">
                  <div>
                    <p className="font-medium">{user.prenom} {user.nom}</p>
                    <p className="text-gray-500 text-sm">{user.email}</p>
                  </div>
                </td>
                <td className="table-cell">
                  <span className={`px-2 py-1 text-xs rounded-full ${roleColors[user.role]}`}>
                    {roleLabels[user.role] || user.role}
                  </span>
                </td>
                <td className="table-cell">{user.telephone || '-'}</td>
                <td className="table-cell">
                  {new Date(user.created_at).toLocaleDateString('fr-CA')}
                </td>
                <td className="table-cell">
                  <button
                    onClick={() => handleDeleteUser(user.id)}
                    className="text-danger-600 hover:text-danger-700 p-2 rounded-lg hover:bg-danger-50 transition-colors"
                  >
                    <Trash2 size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filteredUsers.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            Aucun utilisateur trouvé
          </div>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="card w-full max-w-md max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold">Nouvel utilisateur</h2>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateUser} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Prénom *
                  </label>
                  <input
                    type="text"
                    required
                    value={newUser.prenom}
                    onChange={(e) => setNewUser({ ...newUser, prenom: e.target.value })}
                    className="input"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Nom *
                  </label>
                  <input
                    type="text"
                    required
                    value={newUser.nom}
                    onChange={(e) => setNewUser({ ...newUser, nom: e.target.value })}
                    className="input"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email *
                </label>
                <input
                  type="email"
                  required
                  value={newUser.email}
                  onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                  className="input"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Mot de passe *
                </label>
                <input
                  type="password"
                  required
                  value={newUser.password}
                  onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                  className="input"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Rôle *
                </label>
                <select
                  value={newUser.role}
                  onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
                  className="input"
                >
                  <option value="nurse">Infirmier(ère)</option>
                  <option value="doctor">Médecin</option>
                  <option value="admin">Administrateur</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Téléphone
                </label>
                <input
                  type="tel"
                  value={newUser.telephone}
                  onChange={(e) => setNewUser({ ...newUser, telephone: e.target.value })}
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
                  Créer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
