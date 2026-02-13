'use client';

import { useState } from 'react';
import {
    Clock, Volume2, Shield, Save, CheckCircle
} from 'lucide-react';

export default function SettingsPage() {
    const [waitTimeModifier, setWaitTimeModifier] = useState(0); // in minutes
    const [broadcastMessage, setBroadcastMessage] = useState('');
    const [isBroadcastActive, setIsBroadcastActive] = useState(false);
    const [triageMode, setTriageMode] = useState('auto');
    const [saving, setSaving] = useState(false);

    const handleSave = async () => {
        setSaving(true);
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1000));
        setSaving(false);
        alert('Configuration sauvegardée !');
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Configuration Système</h1>
                <p className="text-gray-400 text-sm mt-0.5">Paramètres globaux de l'application</p>
            </div>

            <div className="grid md:grid-cols-2 gap-6">

                {/* Wait Time Control */}
                <div className="bg-white rounded-2xl p-6 shadow-glass-sm border border-gray-100/80">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
                            <Clock size={20} />
                        </div>
                        <div>
                            <h2 className="font-bold text-gray-900">Temps d'attente</h2>
                            <p className="text-xs text-gray-500">Ajustement global des estimations</p>
                        </div>
                    </div>

                    <div className="space-y-4">
                        <div>
                            <label className="text-sm font-medium text-gray-700 mb-2 block">
                                Modificateur (minutes)
                            </label>
                            <div className="flex items-center gap-4">
                                <input
                                    type="range"
                                    min="-60"
                                    max="120"
                                    value={waitTimeModifier}
                                    onChange={(e) => setWaitTimeModifier(parseInt(e.target.value))}
                                    className="flex-1 accent-blue-600 cursor-pointer"
                                />
                                <span className={`font-mono font-bold w-16 text-right ${waitTimeModifier > 0 ? 'text-red-500' : waitTimeModifier < 0 ? 'text-green-500' : 'text-gray-400'}`}>
                                    {waitTimeModifier > 0 ? '+' : ''}{waitTimeModifier}m
                                </span>
                            </div>
                            <p className="text-[11px] text-gray-400 mt-2">
                                S'ajoute ou se soustrait à l'estimation algorithmique pour tous les patients.
                            </p>
                        </div>
                    </div>
                </div>

                {/* Broadcast System */}
                <div className="bg-white rounded-2xl p-6 shadow-glass-sm border border-gray-100/80">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-xl bg-orange-50 text-orange-600 flex items-center justify-center">
                            <Volume2 size={20} />
                        </div>
                        <div>
                            <h2 className="font-bold text-gray-900">Diffusion Message</h2>
                            <p className="text-xs text-gray-500">Alerte visible par tous les patients</p>
                        </div>
                    </div>

                    <div className="space-y-4">
                        <textarea
                            value={broadcastMessage}
                            onChange={(e) => setBroadcastMessage(e.target.value)}
                            placeholder="Ex: Urgences saturées, temps d'attente élevé..."
                            className="w-full p-3 bg-gray-50 border border-gray-100 rounded-xl text-sm focus:ring-2 focus:ring-orange-100 focus:border-orange-200 outline-none transition-all h-24 resize-none"
                        />
                        <div className="flex items-center justify-between bg-gray-50 p-3 rounded-xl border border-gray-100">
                            <span className="text-sm font-medium text-gray-600">Activer la diffusion</span>
                            <button
                                onClick={() => setIsBroadcastActive(!isBroadcastActive)}
                                className={`relative w-11 h-6 rounded-full transition-colors ${isBroadcastActive ? 'bg-orange-500' : 'bg-gray-300'}`}
                            >
                                <div className={`absolute top-1 left-1 w-4 h-4 bg-white rounded-full transition-transform ${isBroadcastActive ? 'translate-x-5' : 'translate-x-0'}`} />
                            </button>
                        </div>
                    </div>
                </div>

                {/* Triage Mode */}
                <div className="bg-white rounded-2xl p-6 shadow-glass-sm border border-gray-100/80">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
                            <Shield size={20} />
                        </div>
                        <div>
                            <h2 className="font-bold text-gray-900">Mode de Triage</h2>
                            <p className="text-xs text-gray-500">Sensibilité de l'algorithme</p>
                        </div>
                    </div>

                    <div className="space-y-2">
                        {[
                            { id: 'auto', label: 'Automatique (Standard)', desc: 'Algorithme P1-P5 standard' },
                            { id: 'strict', label: 'Strict (Sécurité max)', desc: 'Sur-classe les cas limites en P2' },
                            { id: 'permissive', label: 'Permissif (Désengorgement)', desc: 'Sous-classe léger pour fluidifier' },
                        ].map((mode) => (
                            <label
                                key={mode.id}
                                className={`flex cursor-pointer items-start gap-3 p-3 rounded-xl border transition-all ${triageMode === mode.id ? 'bg-purple-50 border-purple-200 ring-1 ring-purple-200' : 'bg-white border-gray-100 hover:border-gray-200'}`}
                            >
                                <input
                                    type="radio"
                                    name="triageMode"
                                    value={mode.id}
                                    checked={triageMode === mode.id}
                                    onChange={(e) => setTriageMode(e.target.value)}
                                    className="mt-1 w-4 h-4 text-purple-600 accent-purple-600 shrink-0"
                                />
                                <div>
                                    <p className="text-sm font-semibold text-gray-900">{mode.label}</p>
                                    <p className="text-[10px] text-gray-500">{mode.desc}</p>
                                </div>
                            </label>
                        ))}
                    </div>
                </div>

                {/* Save Button */}
                <div className="bg-white rounded-2xl p-6 shadow-glass-sm border border-gray-100/80 flex flex-col justify-center items-center text-center space-y-4">
                    <div className="w-12 h-12 rounded-full bg-gray-50 flex items-center justify-center mb-2">
                        <Save size={24} className="text-gray-400" />
                    </div>
                    <div>
                        <h3 className="font-bold text-gray-900">Sauvegarder la configuration</h3>
                        <p className="text-xs text-gray-500 max-w-[200px] mx-auto">Applique les changements immédiatement à l'ensemble du système.</p>
                    </div>

                    <button
                        onClick={handleSave}
                        disabled={saving}
                        className="w-full max-w-xs bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 rounded-xl transition-all shadow-lg shadow-indigo-500/20 active:scale-95 flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
                    >
                        {saving ? (
                            <>
                                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                <span>Enregistrement...</span>
                            </>
                        ) : (
                            <>
                                <CheckCircle size={18} />
                                <span>Enregistrer</span>
                            </>
                        )}
                    </button>
                </div>
            </div>
        </div>
    );
}
