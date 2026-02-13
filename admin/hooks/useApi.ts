import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3355';

// ── Helper: Get auth token ──────────────────────────────────────
function getAuthToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem('token');
}

// ── Helper: Fetch with auth ─────────────────────────────────────
async function fetchWithAuth(endpoint: string, options: RequestInit = {}) {
    const token = getAuthToken();

    const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers: {
            'Content-Type': 'application/json',
            ...(token && { Authorization: `Bearer ${token}` }),
            ...options.headers,
        },
    });

    if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Network error' }));
        throw new Error(error.error || `HTTP ${response.status}`);
    }

    return response.json();
}

// ── Tickets Hooks ───────────────────────────────────────────────

export function useTickets(hospitalId?: string) {
    return useQuery({
        queryKey: ['tickets', hospitalId],
        queryFn: () => {
            const params = hospitalId ? `?hospital_id=${hospitalId}` : '';
            return fetchWithAuth(`/api/tickets${params}`);
        },
        enabled: !!getAuthToken(),
    });
}

export function useTicket(ticketId: string) {
    return useQuery({
        queryKey: ['ticket', ticketId],
        queryFn: () => fetchWithAuth(`/api/tickets/${ticketId}`),
        enabled: !!ticketId && !!getAuthToken(),
    });
}

export function useUpdateTicket() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: ({ ticketId, data }: { ticketId: string; data: any }) =>
            fetchWithAuth(`/api/tickets/${ticketId}`, {
                method: 'PATCH',
                body: JSON.stringify(data),
            }),
        onSuccess: () => {
            // Invalidate tickets queries to refetch
            queryClient.invalidateQueries({ queryKey: ['tickets'] });
            queryClient.invalidateQueries({ queryKey: ['ticket'] });
        },
    });
}

export function useTriageTicket() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: ({ ticketId, data }: { ticketId: string; data: any }) =>
            fetchWithAuth(`/api/tickets/${ticketId}/triage`, {
                method: 'POST',
                body: JSON.stringify(data),
            }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['tickets'] });
        },
    });
}

// ── Users Hooks ─────────────────────────────────────────────────

export function useUsers() {
    return useQuery({
        queryKey: ['users'],
        queryFn: () => fetchWithAuth('/api/admin/users'),
        enabled: !!getAuthToken(),
    });
}

export function useCreateUser() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (data: any) =>
            fetchWithAuth('/api/admin/users', {
                method: 'POST',
                body: JSON.stringify(data),
            }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['users'] });
        },
    });
}

export function useDeleteUser() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (userId: string) =>
            fetchWithAuth(`/api/admin/users/${userId}`, {
                method: 'DELETE',
            }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['users'] });
        },
    });
}

// ── Stats Hooks ─────────────────────────────────────────────────

export function useStats() {
    return useQuery({
        queryKey: ['stats'],
        queryFn: () => fetchWithAuth('/api/admin/stats'),
        enabled: !!getAuthToken(),
        // Refetch every 30 seconds for real-time stats
        refetchInterval: 30000,
    });
}

// ── Hospitals Hooks ─────────────────────────────────────────────

export function useHospitals() {
    return useQuery({
        queryKey: ['hospitals'],
        queryFn: () => fetchWithAuth('/api/hospitals'),
        enabled: !!getAuthToken(),
        // Hospitals don't change often, cache for longer
        staleTime: 15 * 60 * 1000, // 15 minutes
    });
}
