'use client';

import { useState, useEffect } from 'react';
import { getTickets, updateTicket } from '@/lib/api';
import {
    Activity, Clock, CheckCircle, AlertTriangle, User,
    Thermometer, Heart, Wind, AlertCircle, Save
} from 'lucide-react';

interface Ticket {
    id: string;
    code?: string;
    patient_prenom?: string;
    patient_nom?: string;
    patient_name?: string;
    priority_level: number;
    validated_priority?: number;
    status: string;
    created_at: string;
    symptoms?: string;
}

const priorityConfig: Record<number, { label: string; color: string; bg: string }> = {
    1: { label: 'P1 - Réanimation', color: 'text-red-700', bg: 'bg-red-100 border-red-300' },
    2: { label: 'P2 - Très Urgent', color: 'text-orange-700', bg: 'bg-orange-100 border-orange-300' },
    3: { label: 'P3 - Urgent', color: 'text-yellow-700', bg: 'bg-yellow-100 border-yellow-300' },
    4: { label: 'P4 - Moins Urgent', color: 'text-blue-700', bg: 'bg-blue-100 border-blue-300' },
    5: { label: 'P5 - Non Urgent', color: 'text-green-700', bg: 'bg-green-100 border-green-300' },
};

export default function TriagePage() {
    const [tickets, setTickets] = useState<Ticket[]>([]);
    const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
    const [selectedPriority, setSelectedPriority] = useState<number>(5);
    const [loading, setLoading] = useState(true);
    const [processing, setProcessing] = useState(false);

    useEffect(() => { loadData(); }, []);

    const loadData = async () => {
        try {
            const data = await getTickets();
            // Filter for 'waiting' or 'checked_in' status
            const waiting = (Array.isArray(data) ? data : [])
                .filter((t: Ticket) => ['waiting', 'checked_in'].includes(t.status))
                .sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

            setTickets(waiting);
            if (selectedTicket) {
                // Update selected if it still exists
                const stillExists = waiting.find(t => t.id === selectedTicket.id);
                if (stillExists) setSelectedTicket(stillExists);
                else setSelectedTicket(null);
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const handleSelect = (ticket: Ticket) => {
        setSelectedTicket(ticket);
        setSelectedPriority(ticket.priority_level || 5);
    };

    const handleConfirmTriage = async () => {
        if (!selectedTicket) return;
        setProcessing(true);
        try {
            await updateTicket(selectedTicket.id, {
                status: 'triaged',
                validated_priority: selectedPriority
            });
            // Remove from list locally for instant feedback
            setTickets(tickets.filter(t => t.id !== selectedTicket.id));
            setSelectedTicket(null);
            // Refresh background
            loadData();
        } catch (error) {
            alert('Erreur lors du triage');
        } finally {
            setProcessing(false);
        }
    };

    const getPatientName = (t: Ticket) => t.patient_prenom && t.patient_nom ? `${t.patient_prenom} ${t.patient_nom}` : t.patient_name || 'Anonyme';

    return (
        <div className="h-[calc(100vh-2rem)] flex flex-col md:flex-row gap-6">

            {/* LEFT: Queue List */}
            <div className="w-full md:w-1/3 bg-white rounded-3xl shadow-glass border border-gray-100 flex flex-col overflow-hidden">
                <div className="p-5 border-b border-gray-100 bg-gray-50/50">
                    <h2 className="font-bold text-gray-900 flex items-center gap-2">
                        <User size={20} className="text-blue-600" />
                        File d'attente
                        <span className="bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full text-xs">{tickets.length}</span>
                    </h2>
                </div>

                <div className="flex-1 overflow-y-auto p-3 space-y-2">
                    {loading ? (
                        <div className="text-center py-10 text-gray-400">Chargement...</div>
                    ) : tickets.length === 0 ? (
                        <div className="text-center py-10 text-gray-400 flex flex-col items-center">
                            <CheckCircle size={40} className="mb-2 opacity-20" />
                            <p>Aucun patient en attente</p>
                        </div>
                    ) : (
                        tickets.map(ticket => (
                            <div
                                key={ticket.id}
                                onClick={() => handleSelect(ticket)}
                                className={`p-4 rounded-2xl border transition-all cursor-pointer hover:shadow-md ${selectedTicket?.id === ticket.id
                                        ? 'bg-blue-50 border-blue-200 ring-1 ring-blue-200 shadow-sm'
                                        : 'bg-white border-gray-100 hover:border-gray-200'
                                    }`}
                            >
                                <div className="flex justify-between items-start mb-1">
                                    <h3 className="font-bold text-gray-900">{getPatientName(ticket)}</h3>
                                    <span className="text-xs font-mono text-gray-400">#{ticket.code?.substring(0, 4)}</span>
                                </div>
                                <div className="flex justify-between items-end">
                                    <p className="text-xs text-gray-500 line-clamp-1">{ticket.symptoms || 'Pas de symptômes précisés'}</p>
                                    <span className="text-[10px] bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded">
                                        {new Date(ticket.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                    </span>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>

            {/* RIGHT: Triage Workspace */}
            <div className="flex-1 bg-white rounded-3xl shadow-glass border border-gray-100 flex flex-col overflow-hidden relative">
                {selectedTicket ? (
                    <div className="h-full flex flex-col">
                        {/* Header */}
                        <div className="p-6 border-b border-gray-100 flex justify-between items-start">
                            <div>
                                <h1 className="text-3xl font-bold text-gray-900 mb-1">{getPatientName(selectedTicket)}</h1>
                                <div className="flex items-center gap-3 text-gray-500 text-sm">
                                    <span className="flex items-center gap-1"><Clock size={16} /> Arrivé à {new Date(selectedTicket.created_at).toLocaleTimeString()}</span>
                                    <span className="bg-amber-100 text-amber-700 px-2 py-0.5 rounded text-xs font-bold">À TRIER</span>
                                </div>
                            </div>
                            <div className="text-right">
                                <p className="text-sm text-gray-400">Priorité suggérée</p>
                                <p className="text-2xl font-bold text-gray-900">P{selectedTicket.priority_level}</p>
                            </div>
                        </div>

                        {/* Content */}
                        <div className="flex-1 overflow-y-auto p-6">

                            {/* Symptoms */}
                            <div className="mb-8">
                                <h3 className="text-sm font-bold text-gray-400 uppercase mb-3 flex items-center gap-2">
                                    <AlertCircle size={16} /> Symptômes déclarés
                                </h3>
                                <div className="bg-gray-50 p-4 rounded-2xl border border-gray-100 text-gray-800 text-lg">
                                    {selectedTicket.symptoms || "Aucun symptôme déclaré."}
                                </div>
                            </div>

                            {/* Priority Selection */}
                            <div className="mb-8">
                                <h3 className="text-sm font-bold text-gray-400 uppercase mb-3 flex items-center gap-2">
                                    <Activity size={16} /> Évaluation de la priorité
                                </h3>
                                <div className="grid grid-cols-1 md:grid-cols-5 gap-3">
                                    {[1, 2, 3, 4, 5].map(p => {
                                        const cfg = priorityConfig[p];
                                        const isSelected = selectedPriority === p;
                                        return (
                                            <button
                                                key={p}
                                                onClick={() => setSelectedPriority(p)}
                                                className={`p-4 rounded-xl border-2 transition-all flex flex-col items-center justify-center gap-2 text-center h-32 ${isSelected
                                                        ? `${cfg.bg} ring-2 ring-offset-2 ring-gray-300 transform scale-105 shadow-lg`
                                                        : 'bg-white border-gray-100 hover:border-gray-200 text-gray-400 hover:text-gray-600'
                                                    }`}
                                            >
                                                <span className={`text-2xl font-black ${isSelected ? cfg.color : ''}`}>P{p}</span>
                                                <span className={`text-xs font-bold ${isSelected ? cfg.color : ''}`}>{cfg.label.split(' - ')[1]}</span>
                                            </button>
                                        )
                                    })}
                                </div>
                            </div>

                            {/* Vitals (Placeholder for MVP) */}
                            <div>
                                <h3 className="text-sm font-bold text-gray-400 uppercase mb-3 flex items-center gap-2">
                                    <Heart size={16} /> Constantes (Optionnel)
                                </h3>
                                <div className="grid grid-cols-3 gap-4">
                                    <div className="bg-gray-50 p-3 rounded-xl border border-gray-100 opacity-50 cursor-not-allowed">
                                        <span className="text-xs text-gray-400 block mb-1">Tension</span>
                                        <span className="font-mono text-lg text-gray-300">--/--</span>
                                    </div>
                                    <div className="bg-gray-50 p-3 rounded-xl border border-gray-100 opacity-50 cursor-not-allowed">
                                        <span className="text-xs text-gray-400 block mb-1">SPO2</span>
                                        <span className="font-mono text-lg text-gray-300">--%</span>
                                    </div>
                                    <div className="bg-gray-50 p-3 rounded-xl border border-gray-100 opacity-50 cursor-not-allowed">
                                        <span className="text-xs text-gray-400 block mb-1">Temp.</span>
                                        <span className="font-mono text-lg text-gray-300">--°C</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Footer Action */}
                        <div className="p-6 bg-white border-t border-gray-100 shadow-[0_-10px_40px_rgba(0,0,0,0.05)] z-10 flex justify-end">
                            <button
                                onClick={handleConfirmTriage}
                                disabled={processing}
                                className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-4 px-8 rounded-2xl shadow-xl shadow-indigo-500/30 active:scale-95 transition-all flex items-center gap-3 text-lg disabled:opacity-70"
                            >
                                {processing ? (
                                    <>
                                        <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                        <span>Validation...</span>
                                    </>
                                ) : (
                                    <>
                                        <Save size={24} />
                                        <span>Confirmer le triage (P{selectedPriority})</span>
                                    </>
                                )}
                            </button>
                        </div>

                    </div>
                ) : (
                    <div className="flex-1 flex flex-col items-center justify-center text-gray-400 bg-gray-50/30">
                        <Activity size={64} className="mb-4 opacity-10" />
                        <h3 className="text-xl font-bold text-gray-300">Prêt pour le triage</h3>
                        <p className="text-sm">Sélectionnez un patient dans la file d'attente</p>
                    </div>
                )}
            </div>
        </div>
    );
}
