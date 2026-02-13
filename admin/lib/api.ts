const isProduction = process.env.NODE_ENV === 'production';
const API_URL = process.env.NEXT_PUBLIC_API_URL || (isProduction ? 'https://api.allo-urgence.tech-afm.com' : 'http://localhost:3355');

export async function fetchApi(endpoint: string, options: RequestInit = {}) {
  const token = typeof window !== 'undefined' ? localStorage.getItem('admin_token') : null;

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
    body: JSON.stringify({ email, password, client: 'admin' }),
  });

// Users
export const getUsers = () => fetchApi('/admin/users').then(d => d.users || d);
export const createUser = (data: any) =>
  fetchApi('/admin/users', { method: 'POST', body: JSON.stringify(data) });
export const updateUser = (id: string, data: any) =>
  fetchApi(`/admin/users/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
export const deleteUser = (id: string) =>
  fetchApi(`/admin/users/${id}`, { method: 'DELETE' });

// Hospitals
export const getHospitals = () => fetchApi('/hospitals').then(d => d.hospitals || d);
export const createHospital = (data: any) =>
  fetchApi('/admin/hospitals', { method: 'POST', body: JSON.stringify(data) });
export const updateHospital = (id: string, data: any) =>
  fetchApi(`/admin/hospitals/${id}`, { method: 'PATCH', body: JSON.stringify(data) });
export const deleteHospital = (id: string) =>
  fetchApi(`/admin/hospitals/${id}`, { method: 'DELETE' });

// Tickets
export const getTickets = (params?: Record<string, string>) => {
  const qs = params ? '?' + new URLSearchParams(params).toString() : '';
  return fetchApi(`/admin/tickets${qs}`).then(d => d.tickets || d);
};
export const getTicket = (id: string) => fetchApi(`/tickets/${id}`);
export const updateTicket = (id: string, data: any) =>
  fetchApi(`/admin/tickets/${id}`, { method: 'PATCH', body: JSON.stringify(data) });

// Stats
export const getDashboardStats = () => fetchApi('/admin/stats');
