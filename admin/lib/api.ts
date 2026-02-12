const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3355';

export async function fetchApi(endpoint: string, options: RequestInit = {}) {
  const token = localStorage.getItem('admin_token');
  
  const response = await fetch(`${API_URL}/api${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { 'Authorization': `Bearer ${token}` }),
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Erreur serveur' }));
    throw new Error(error.error || `HTTP ${response.status}`);
  }

  return response.json();
}

// Auth
export const login = (email: string, password: string) =>
  fetchApi('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });

// Users
export const getUsers = () => fetchApi('/admin/users');
export const createUser = (data: any) =>
  fetchApi('/admin/users', { method: 'POST', body: JSON.stringify(data) });
export const deleteUser = (id: string) =>
  fetchApi(`/admin/users/${id}`, { method: 'DELETE' });

// Hospitals
export const getHospitals = () => fetchApi('/hospitals');
export const createHospital = (data: any) =>
  fetchApi('/hospitals', { method: 'POST', body: JSON.stringify(data) });
export const updateHospital = (id: string, data: any) =>
  fetchApi(`/hospitals/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
export const deleteHospital = (id: string) =>
  fetchApi(`/hospitals/${id}`, { method: 'DELETE' });

// Tickets
export const getTickets = () => fetchApi('/tickets');
export const getTicketStats = () => fetchApi('/tickets/stats');

// Stats
export const getDashboardStats = () => fetchApi('/admin/stats');
