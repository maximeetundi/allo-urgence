const express = require('express');
const router = express.Router();
const { triageQuestions, calculatePriority, getPriorityLabel, getPriorityColor } = require('../config/triage');
const { authenticateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const Joi = require('joi');
const logger = require('../utils/logger');

// ── Validation Schema ────────────────────────────────────────────

const triageAnswersSchema = Joi.object({
    q1_problem_type: Joi.string().valid(
        'accident_trauma', 'breathing', 'chest_pain', 'severe_pain',
        'fever', 'minor_injury', 'consultation'
    ).required(),
    q2_pain_level: Joi.number().min(0).max(10).required(),
    q3_breathing_difficulty: Joi.string().valid('yes', 'no').required(),
    q4_bleeding: Joi.string().valid('none', 'light', 'moderate', 'severe').required(),
    q5_consciousness: Joi.string().valid('yes', 'no').required(),
    q6_symptom_duration: Joi.string().valid('less_1h', '1_6h', '6_24h', 'more_24h').required(),
    q7_chronic_condition: Joi.string().valid('yes', 'no').optional(),
});

// ── GET /api/triage/questions ────────────────────────────────────
// Retourne la liste des questions de pré-triage

router.get('/questions', (req, res) => {
    try {
        logger.info('Fetching triage questions');

        res.json({
            questions: triageQuestions,
            disclaimer: 'Le niveau de priorité estimé sera validé par un professionnel de santé.',
        });
    } catch (err) {
        logger.error('Error fetching triage questions', { error: err.message });
        res.status(500).json({ error: 'Erreur lors de la récupération des questions' });
    }
});

// ── POST /api/triage/calculate ──────────────────────────────────
// Calcule la priorité estimée basée sur les réponses

router.post('/calculate', validate(triageAnswersSchema), (req, res) => {
    try {
        const answers = req.body;

        logger.info('Calculating triage priority', { answers });

        const result = calculatePriority(answers);
        const label = getPriorityLabel(result.priority);
        const color = getPriorityColor(result.priority);

        res.json({
            priority: result.priority,
            label,
            color,
            confidence: result.confidence,
            disclaimer: 'Cette estimation sera validée par un professionnel de santé lors de votre arrivée.',
            recommendations: getRecommendations(result.priority),
        });
    } catch (err) {
        logger.error('Error calculating triage priority', { error: err.message });
        res.status(500).json({ error: 'Erreur lors du calcul de la priorité' });
    }
});

// ── Helper: Recommandations basées sur priorité ─────────────────

function getRecommendations(priority) {
    const recommendations = {
        1: {
            message: 'Situation critique - Rendez-vous immédiatement à l\'urgence',
            urgency: 'IMMÉDIAT',
            icon: '🚨',
        },
        2: {
            message: 'Situation très urgente - Rendez-vous à l\'urgence dès que possible',
            urgency: 'TRÈS URGENT',
            icon: '🔴',
        },
        3: {
            message: 'Situation urgente - Présentez-vous à l\'urgence',
            urgency: 'URGENT',
            icon: '🟠',
        },
        4: {
            message: 'Situation moins urgente - Vous pouvez attendre le moment recommandé',
            urgency: 'MOINS URGENT',
            icon: '🟡',
        },
        5: {
            message: 'Situation non urgente - Consultez selon votre disponibilité',
            urgency: 'NON URGENT',
            icon: '🟢',
        },
    };

    return recommendations[priority] || recommendations[5];
}

module.exports = router;
