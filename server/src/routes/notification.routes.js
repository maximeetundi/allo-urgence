const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { registerDeviceToken } = require('../services/notification.service');
const { validate } = require('../middleware/validation');
const Joi = require('joi');
const logger = require('../utils/logger');

// ── Validation Schema ────────────────────────────────────────────

const registerTokenSchema = Joi.object({
    token: Joi.string().required(),
    platform: Joi.string().valid('android', 'ios').required(),
});

// ── POST /api/notifications/register ────────────────────────────
// Register device token for push notifications

router.post('/register', authenticateToken, validate(registerTokenSchema), async (req, res) => {
    try {
        const { token, platform } = req.body;
        const userId = req.user.id;

        await registerDeviceToken(userId, token, platform);

        logger.info('Device token registered', { userId, platform });

        res.json({
            success: true,
            message: 'Token enregistré avec succès',
        });
    } catch (err) {
        logger.error('Error registering device token', { error: err.message });
        res.status(500).json({ error: 'Erreur lors de l\'enregistrement du token' });
    }
});

// ── DELETE /api/notifications/unregister ────────────────────────
// Unregister device token

router.delete('/unregister', authenticateToken, async (req, res) => {
    try {
        const { token } = req.body;
        const userId = req.user.id;

        const db = require('../db/pg_connection');
        await db.query(
            `DELETE FROM device_tokens WHERE user_id = $1 AND token = $2`,
            [userId, token]
        );

        logger.info('Device token unregistered', { userId });

        res.json({
            success: true,
            message: 'Token supprimé avec succès',
        });
    } catch (err) {
        logger.error('Error unregistering device token', { error: err.message });
        res.status(500).json({ error: 'Erreur lors de la suppression du token' });
    }
});

// ── GET /api/notifications ──────────────────────────────────────
// Get user activity history (from audit_log and tickets)
router.get('/', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const db = require('../db/pg_connection');

        // Fetch audit logs for the user
        const result = await db.query(
            `SELECT * FROM audit_log 
             WHERE user_id = $1 
             ORDER BY created_at DESC 
             LIMIT 50`,
            [userId]
        );

        // Map logs to user-friendly notifications
        const notifications = result.rows.map(log => {
            let title = 'Activité';
            let message = log.details;
            let icon = 'info';

            // Details is often a JSON string or object, checking type might be needed
            // But log.details schema says TEXT. 
            // Often auditLog is called with object details which are stringified?
            // "details TEXT" in schema.
            // ticket.routes.js: auditLog(..., { ticketId... }) -> likely JSON.stringify?
            // middleware/auth.js auditLog implementation?
            // Assuming details is JSON string, let's try to parse if needed.
            let detailsObj = {};
            try {
                if (typeof log.details === 'string' && (log.details.startsWith('{') || log.details.startsWith('['))) {
                    detailsObj = JSON.parse(log.details);
                } else {
                    detailsObj = { message: log.details };
                }
            } catch (e) { detailsObj = { message: log.details }; }

            switch (log.action) {
                case 'ticket_created':
                    title = 'Ticket créé';
                    message = 'Vous avez créé une nouvelle demande de prise en charge.';
                    icon = 'ticket';
                    break;
                case 'ticket_triaged':
                    title = 'Triage effectué';
                    message = 'Votre dossier a été trié par un infirmier.';
                    icon = 'triage';
                    break;
                case 'ticket_treated':
                    title = 'Prise en charge';
                    message = 'Votre dossier a été traité par un médecin.';
                    icon = 'doctor';
                    break;
                case 'profile_update':
                    title = 'Profil mis à jour';
                    message = 'Vos informations personnelles ont été modifiées.';
                    icon = 'profile';
                    break;
            }

            return {
                id: log.id,
                title,
                message,
                icon,
                created_at: log.created_at,
                read: true,
            };
        });

        res.json({ notifications });
    } catch (err) {
        logger.error('Error fetching notifications', { error: err.message });
        res.status(500).json({ error: 'Erreur lors du chargement des notifications' });
    }
});

module.exports = router;
