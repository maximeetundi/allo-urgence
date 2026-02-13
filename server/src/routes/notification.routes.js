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

module.exports = router;
