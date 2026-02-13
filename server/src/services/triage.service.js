// Service de pré-triage — Logique de mapping questionnaire → priorité
// Basé sur l'Échelle canadienne de triage et de gravité (ÉTG)

const TRIAGE_CATEGORIES = [
    {
        id: 'cardiac_arrest',
        label: 'Arrêt cardiaque / Inconscience',
        icon: '🔴',
        color: '#DC2626',
        priority: 1,
        description: 'La personne ne respire pas ou est inconsciente'
    },
    {
        id: 'severe_trauma',
        label: 'Accident grave / Traumatisme sévère',
        icon: '🔴',
        color: '#DC2626',
        priority: 2,
        description: 'Accident de voiture, chute grave, blessure importante'
    },
    {
        id: 'breathing_difficulty',
        label: 'Difficulté respiratoire',
        icon: '🔴',
        color: '#DC2626',
        priority: 2,
        description: 'Essoufflement sévère, incapacité à respirer normalement'
    },
    {
        id: 'chest_pain',
        label: 'Douleur thoracique',
        icon: '🔴',
        color: '#DC2626',
        priority: 2,
        description: 'Douleur à la poitrine, pression, serrement'
    },
    {
        id: 'severe_pain',
        label: 'Douleur sévère',
        icon: '🟠',
        color: '#EA580C',
        priority: 3,
        description: 'Douleur intense (8-10/10)'
    },
    {
        id: 'high_fever',
        label: 'Fièvre élevée',
        icon: '🟠',
        color: '#EA580C',
        priority: 3,
        description: 'Fièvre > 39°C avec malaise général'
    },
    {
        id: 'moderate_injury',
        label: 'Blessure modérée',
        icon: '🟠',
        color: '#EA580C',
        priority: 3,
        description: 'Fracture possible, coupure profonde'
    },
    {
        id: 'mild_infection',
        label: 'Infection mineure',
        icon: '🟡',
        color: '#CA8A04',
        priority: 4,
        description: 'Infection urinaire, otite, sinusite'
    },
    {
        id: 'minor_injury',
        label: 'Blessure légère',
        icon: '🟡',
        color: '#CA8A04',
        priority: 4,
        description: 'Entorse, petite coupure, ecchymose'
    },
    {
        id: 'mild_symptoms',
        label: 'Symptômes légers',
        icon: '🟢',
        color: '#16A34A',
        priority: 5,
        description: 'Rhume, mal de gorge, léger malaise'
    },
    {
        id: 'consultation',
        label: 'Consultation simple',
        icon: '🟢',
        color: '#16A34A',
        priority: 5,
        description: 'Renouvellement, question de santé, suivi'
    }
];

const FOLLOW_UP_QUESTIONS = [
    {
        id: 'pain_level',
        question: 'Sur une échelle de 1 à 10, quel est votre niveau de douleur ?',
        type: 'slider',
        min: 0,
        max: 10,
        affects_priority: true
    },
    {
        id: 'symptom_duration',
        question: 'Depuis combien de temps avez-vous ces symptômes ?',
        type: 'choice',
        options: [
            { label: 'Moins d\'une heure', value: 'under_1h', priority_modifier: -1 },
            { label: '1 à 24 heures', value: '1_24h', priority_modifier: 0 },
            { label: 'Plus de 24 heures', value: 'over_24h', priority_modifier: 1 }
        ]
    },
    {
        id: 'breathing',
        question: 'Avez-vous des difficultés à respirer ?',
        type: 'boolean',
        priority_modifier_if_yes: -1
    },
    {
        id: 'chronic_condition',
        question: 'Avez-vous une condition chronique (diabète, asthme, etc.) ?',
        type: 'boolean',
        priority_modifier_if_yes: 0,
        note: 'Information pour le personnel soignant'
    }
];

function calculatePriority(categoryId, answers) {
    const category = TRIAGE_CATEGORIES.find(c => c.id === categoryId);
    if (!category) return { priority: 4, category: 'unknown' };

    let priority = category.priority;

    // Adjust based on pain level
    if (answers.pain_level !== undefined) {
        if (answers.pain_level >= 9 && priority > 2) priority = 2;
        else if (answers.pain_level >= 7 && priority > 3) priority = 3;
    }

    // Adjust based on breathing difficulty
    if (answers.breathing === true && priority > 2) {
        priority = Math.max(2, priority - 1);
    }

    // Adjust based on symptom duration (acute = more urgent)
    if (answers.symptom_duration === 'under_1h' && priority > 2) {
        priority = Math.max(2, priority - 1);
    }

    // Clamp to valid range
    priority = Math.max(1, Math.min(5, priority));

    return {
        priority,
        category: category.label,
        categoryId: category.id,
        disclaimer: 'Le niveau final sera confirmé par un professionnel de santé.'
    };
}

// Estimated wait times per priority level (in minutes)
function getEstimatedWait(priorityLevel, currentQueueCounts) {
    const baseWait = {
        1: 0,    // Réanimation — immédiat
        2: 15,   // Très urgent
        3: 30,   // Urgent
        4: 60,   // Moins urgent
        5: 120   // Non urgent
    };

    let wait = baseWait[priorityLevel] || 60;

    // Add time based on people ahead in queue with same or higher priority
    if (currentQueueCounts) {
        for (let p = 1; p <= priorityLevel; p++) {
            wait += (currentQueueCounts[p] || 0) * 10;
        }
    }

    return wait;
}

// Helper to get all categories
function getCategories() {
    return TRIAGE_CATEGORIES;
}

function getFollowUpQuestions() {
    return FOLLOW_UP_QUESTIONS;
}

module.exports = {
    TRIAGE_CATEGORIES,
    FOLLOW_UP_QUESTIONS,
    calculatePriority,
    getEstimatedWait,
    getCategories,
    getFollowUpQuestions
};
