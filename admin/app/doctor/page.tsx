'use client';

import { useState, useEffect } from 'react';
import { getTickets, updateTicket } from '@/lib/api';
import {
    Stethoscope, Clock, CheckCircle, AlertCircle, User,
    FileText, Activity, ArrowRight, Play, Check
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

const priorityConfig: Record<number, { label: string; color: string; bg: string; dot: string }> = {
    1: { label: 'P1 - Réanimation', color: 'text-red-700', bg: 'bg-red-50 border-red-200', dot: 'bg-red-500' },
    2: { label: 'P2 - Très Urgent', color: 'text-orange-700', bg: 'bg-orange-50 border-orange-200', dot: 'bg-orange-500' },
    3: { label: 'P3 - Urgent', color: 'text-yellow-700', bg: 'bg-yellow-50 border-yellow-200', dot: 'bg-yellow-500' },
    4: { label: 'P4 - Moins Urgent', color: 'text-blue-700', bg: 'bg-blue-50 border-blue-200', dot: 'bg-blue-500' },
    5: { label: 'P5 - Non Urgent', color: 'text-green-700', bg: 'bg-green-50 border-green-200', dot: 'bg-green-500' },
};

export default function DoctorPage() {
    const [tickets, setTickets] = useState<Ticket[]>([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState<'waiting' | 'my_patients'>('waiting');
    const [processingId, setProcessingId] = useState<string | null>(null);

    useEffect(() => { loadData(); }, []);

    const loadData = async () => {
        setLoading(true);
        try {
            const data = await getTickets();
            const relevant = (Array.isArray(data) ? data : [])
                .filter((t: Ticket) => ['triaged', 'in_progress'].includes(t.status))
                .sort((a, b) => {
                    // Sort P1 -> P5
                    const prioA = a.validated_priority || a.priority_level || 5;
                    const prioB = b.validated_priority || b.priority_level || 5;
                    if (prioA !== prioB) return prioA - prioB;
                    // Then by wait time (older first)
                    return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
                });
            setTickets(relevant);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const handleAction = async (id: string, action: 'take' | 'finish') => {
        setProcessingId(id);
        try {
            const updates = action === 'take'
                ? { status: 'in_progress' }
                : { status: 'treated' }; // Or 'completed'? check consistency

            await updateTicket(id, updates);

            // Optimistic update
            if (action === 'finish') {
                setTickets(tickets.filter(t => t.id !== id));
            } else {
                setTickets(tickets.map(t => t.id === id ? { ...t, status: 'in_progress' } : t));
            }
        } catch (error) {
            alert('Erreur action');
        } finally {
            setProcessingId(null);
        }
    };

    const getPatientName = (t: Ticket) => t.patient_prenom && t.patient_nom ? `${t.patient_prenom} ${t.patient_nom}` : t.patient_name || 'Anonyme';

    const waitingList = tickets.filter(t => t.status === 'triaged');
    const myPatients = tickets.filter(t => t.status === 'in_progress');

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Espace Médecin</h1>
                    <p className="text-gray-400 text-sm mt-0.5">Patients prêts pour consultation</p>
                </div>
                <div className="flex bg-gray-100 p-1 rounded-xl">
                    <button
                        onClick={() => setActiveTab('waiting')}
                        className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'waiting' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
                            }`}
                    >
                        À voir ({waitingList.length})
                    </button>
                    <button
                        onClick={() => setActiveTab('my_patients')}
                        className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'my_patients' ? 'bg-white text-indigo-600 shadow-sm' : 'text-gray-500 hover:text-gray-700'
                            }`}
                    >
                        En cours ({myPatients.length})
                    </button>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-4">
                {loading ? (
                    <div className="text-center py-20">Chargement...</div>
                ) : (activeTab === 'waiting' ? waitingList : myPatients).length === 0 ? (
                    <div className="bg-white rounded-3xl p-16 text-center border dashed border-gray-200">
                        <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4 text-gray-300">
                            <CheckCircle size={32} />
                        </div>
                        <h3 className="text-lg font-bold text-gray-900">Aucun patient</h3>
                        <p className="text-gray-400">Tout est calme pour le moment.</p>
                    </div>
                ) : (
                    (activeTab === 'waiting' ? waitingList : myPatients).map(ticket => {
                        const prio = ticket.validated_priority || ticket.priority_level || 5;
                        const cfg = priorityConfig[prio];
                        const isProcessing = processingId === ticket.id;

                        return (
                            <div key={ticket.id} className="bg-white rounded-2xl p-5 shadow-glass-sm border border-gray-100/80 flex flex-col md:flex-row gap-4 items-center animate-slide-up">
                                {/* Priority Badge */}
                                <div className={`w-14 h-14 rounded-xl flex flex-col items-center justify-center shrink-0 ${cfg.bg}`}>
                                    <span className={`text-xl font-black ${cfg.color}`}>P{prio}</span>
                                </div>

                                {/* Info */}
                                <div className="flex-1 min-w-0 text-center md:text-left">
                                    <h3 className="text-lg font-bold text-gray-900 truncate">{getPatientName(ticket)}</h3>
                                    <div className="flex flex-wrap items-center justify-center md:justify-start gap-3 mt-1 text-sm text-gray-500">
                                        <span className="flex items-center gap-1"><Clock size={14} /> {new Date(ticket.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                                        <span className="hidden md:inline">•</span>
                                        <span className="flex items-center gap-1"><Activity size={14} /> {ticket.symptoms || 'Symptômes non précisés'}</span>
                                    </div>
                                </div>

                                {/* Actions */}
                                <div className="shrink-0 flex gap-3 w-full md:w-auto">
                                    {activeTab === 'waiting' ? (
                                        <button
                                            onClick={() => handleAction(ticket.id, 'take')}
                                            disabled={isProcessing}
                                            className="flex-1 md:flex-none btn bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl px-6 py-3 font-bold shadow-lg shadow-indigo-500/20 active:scale-95 flex items-center justify-center gap-2"
                                        >
                                            {isProcessing ? '...' : <><Play size={18} fill="currentColor" /> Prendre en charge</>}
                                        </button>
                                    ) : (
                                        <button
                                            onClick={() => handleAction(ticket.id, 'finish')}
                                            disabled={isProcessing}
                                            className="flex-1 md:flex-none btn bg-emerald-500 hover:bg-emerald-600 text-white rounded-xl px-6 py-3 font-bold shadow-lg shadow-emerald-500/20 active:scale-95 flex items-center justify-center gap-2"
                                        >
                                            {isProcessing ? '...' : <><Check size={18} /> Terminer le soin</>}
                                        </button>
                                    )}
                                </div>
                            </div>
                        );
                    })
                )}
            </div>
        </div>
    );
}
