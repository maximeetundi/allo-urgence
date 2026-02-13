// ── Triage Questions Configuration ──────────────────────────────

/**
 * Questions de pré-triage basées sur l'échelle québécoise (ETG)
 * Permet d'estimer la priorité avant validation par infirmier
 */

const triageQuestions = [
    {
        id: 'q1_problem_type',
        question: 'Quel est le type de problème?',
        type: 'single_choice',
        required: true,
        options: [
            {
                id: 'accident_trauma',
                label: 'Accident / Traumatisme',
                icon: '🚑',
                color: '#ef4444',
                priority_weight: 2,
            },
            {
                id: 'breathing',
                label: 'Difficulté respiratoire',
                icon: '🫁',
                color: '#ef4444',
                priority_weight: 1,
            },
            {
                id: 'chest_pain',
                label: 'Douleur thoracique',
                icon: '💔',
                color: '#ef4444',
                priority_weight: 1,
            },
            {
                id: 'severe_pain',
                label: 'Douleur sévère',
                icon: '😣',
                color: '#f97316',
                priority_weight: 3,
            },
            {
                id: 'fever',
                label: 'Fièvre élevée',
                icon: '🌡️',
                color: '#f59e0b',
                priority_weight: 4,
            },
            {
                id: 'minor_injury',
                label: 'Blessure légère',
                icon: '🩹',
                color: '#eab308',
                priority_weight: 4,
            },
            {
                id: 'consultation',
                label: 'Consultation simple',
                icon: '💬',
                color: '#22c55e',
                priority_weight: 5,
            },
        ],
    },
    {
        id: 'q2_pain_level',
        question: 'Niveau de douleur (0 = aucune, 10 = insupportable)',
        type: 'scale',
        required: true,
        min: 0,
        max: 10,
        calculateWeight: (value) => {
            if (value >= 9) return 1;
            if (value >= 7) return 2;
            if (value >= 5) return 3;
            if (value >= 3) return 4;
            return 5;
        },
    },
    {
        id: 'q3_breathing_difficulty',
        question: 'Avez-vous de la difficulté à respirer?',
        type: 'yes_no',
        required: true,
        yes_weight: 1,
        no_weight: null,
    },
    {
        id: 'q4_bleeding',
        question: 'Y a-t-il un saignement?',
        type: 'single_choice',
        required: true,
        options: [
            { id: 'none', label: 'Aucun', priority_weight: null },
            { id: 'light', label: 'Léger', priority_weight: 3 },
            { id: 'moderate', label: 'Modéré', priority_weight: 2 },
            { id: 'severe', label: 'Important', priority_weight: 1 },
        ],
    },
    {
        id: 'q5_consciousness',
        question: 'Avez-vous eu une perte de conscience?',
        type: 'yes_no',
        required: true,
        yes_weight: 1,
        no_weight: null,
    },
    {
        id: 'q6_symptom_duration',
        question: 'Depuis combien de temps avez-vous ces symptômes?',
        type: 'single_choice',
        required: true,
        options: [
            { id: 'less_1h', label: 'Moins d\'1 heure', priority_weight: 2 },
            { id: '1_6h', label: '1 à 6 heures', priority_weight: 3 },
            { id: '6_24h', label: '6 à 24 heures', priority_weight: 4 },
            { id: 'more_24h', label: 'Plus de 24 heures', priority_weight: 5 },
        ],
    },
    {
        id: 'q7_chronic_condition',
        question: 'Avez-vous une condition médicale chronique pertinente?',
        type: 'yes_no',
        required: false,
        yes_weight: -1, // Augmente légèrement la priorité
        no_weight: null,
    },
];

/**
 * Calcule la priorité estimée basée sur les réponses
 * @param {Object} answers - Réponses du patient
 * @returns {Object} { priority: 1-5, confidence: 0-100 }
 */
function calculatePriority(answers) {
    const weights = [];
    let hasEmergencyFlag = false;

    // Q1: Type de problème
    if (answers.q1_problem_type) {
        const option = triageQuestions[0].options.find(o => o.id === answers.q1_problem_type);
        if (option) {
            weights.push(option.priority_weight);
            if (option.priority_weight <= 2) hasEmergencyFlag = true;
        }
    }

    // Q2: Niveau de douleur
    if (answers.q2_pain_level !== undefined) {
        const weight = triageQuestions[1].calculateWeight(answers.q2_pain_level);
        weights.push(weight);
        if (weight === 1) hasEmergencyFlag = true;
    }

    // Q3: Difficulté respiratoire
    if (answers.q3_breathing_difficulty === 'yes') {
        weights.push(1);
        hasEmergencyFlag = true;
    }

    // Q4: Saignement
    if (answers.q4_bleeding) {
        const option = triageQuestions[3].options.find(o => o.id === answers.q4_bleeding);
        if (option && option.priority_weight) {
            weights.push(option.priority_weight);
            if (option.priority_weight === 1) hasEmergencyFlag = true;
        }
    }

    // Q5: Perte de conscience
    if (answers.q5_consciousness === 'yes') {
        weights.push(1);
        hasEmergencyFlag = true;
    }

    // Q6: Durée symptômes
    if (answers.q6_symptom_duration) {
        const option = triageQuestions[5].options.find(o => o.id === answers.q6_symptom_duration);
        if (option) {
            weights.push(option.priority_weight);
        }
    }

    // Q7: Condition chronique (ajuste légèrement)
    if (answers.q7_chronic_condition === 'yes' && weights.length > 0) {
        const minWeight = Math.min(...weights);
        if (minWeight > 1) {
            weights.push(minWeight - 1);
        }
    }

    // Calcul priorité finale
    if (weights.length === 0) {
        return { priority: 5, confidence: 50 };
    }

    // Priorité = moyenne pondérée, arrondie
    const avgWeight = weights.reduce((sum, w) => sum + w, 0) / weights.length;
    let priority = Math.round(avgWeight);

    // Si flag urgence, forcer P1 ou P2
    if (hasEmergencyFlag && priority > 2) {
        priority = 2;
    }

    // Assurer 1-5
    priority = Math.max(1, Math.min(5, priority));

    // Confiance basée sur nombre de réponses
    const totalQuestions = triageQuestions.filter(q => q.required).length;
    const answeredQuestions = Object.keys(answers).length;
    const confidence = Math.round((answeredQuestions / totalQuestions) * 100);

    return { priority, confidence };
}

/**
 * Obtient le label de priorité
 */
function getPriorityLabel(priority) {
    const labels = {
        1: 'P1 — Réanimation',
        2: 'P2 — Très urgent',
        3: 'P3 — Urgent',
        4: 'P4 — Moins urgent',
        5: 'P5 — Non urgent',
    };
    return labels[priority] || 'Inconnu';
}

/**
 * Obtient la couleur de priorité
 */
function getPriorityColor(priority) {
    const colors = {
        1: '#ef4444',
        2: '#f97316',
        3: '#eab308',
        4: '#3b82f6',
        5: '#22c55e',
    };
    return colors[priority] || '#6b7280';
}

module.exports = {
    triageQuestions,
    calculatePriority,
    getPriorityLabel,
    getPriorityColor,
};
