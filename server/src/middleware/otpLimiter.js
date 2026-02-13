const db = require('../db/pg_connection');
const logger = require('../utils/logger');

// ── OTP Verification Rate Limiter ──────────────────────────────

/**
 * Limite les tentatives de vérification OTP par utilisateur
 * - Max 10 tentatives par heure
 * - Tracking dans la base de données
 */
async function otpVerificationLimiter(req, res, next) {
    try {
        const userId = req.user?.id;

        if (!userId) {
            return next();
        }

        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

        // Compter les tentatives de la dernière heure
        const result = await db.query(
            `SELECT COUNT(*) as count FROM verification_attempts 
       WHERE user_id = $1 AND attempt_type = 'verify' AND created_at > $2`,
            [userId, oneHourAgo]
        );

        const attemptCount = parseInt(result.rows[0]?.count || 0);

        if (attemptCount >= 10) {
            logger.warn('OTP verification rate limit exceeded', {
                userId,
                attempts: attemptCount,
            });

            return res.status(429).json({
                error: 'Trop de tentatives de vérification. Veuillez réessayer dans 1 heure',
            });
        }

        // Enregistrer cette tentative
        await db.query(
            `INSERT INTO verification_attempts (user_id, attempt_type) VALUES ($1, $2)`,
            [userId, 'verify']
        );

        next();
    } catch (err) {
        logger.error('OTP rate limiter error', { error: err.message });
        // En cas d'erreur, laisser passer (fail-open pour ne pas bloquer le service)
        next();
    }
}

/**
 * Limite les demandes de renvoi OTP par utilisateur
 * - Max 5 renvois par heure (en plus du rate limiter express)
 * - Délai exponentiel entre les renvois
 */
async function otpResendLimiter(req, res, next) {
    try {
        const userId = req.user?.id;

        if (!userId) {
            return next();
        }

        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

        // Compter les renvois de la dernière heure
        const result = await db.query(
            `SELECT COUNT(*) as count, MAX(created_at) as last_attempt 
       FROM verification_attempts 
       WHERE user_id = $1 AND attempt_type = 'resend' AND created_at > $2`,
            [userId, oneHourAgo]
        );

        const attemptCount = parseInt(result.rows[0]?.count || 0);
        const lastAttempt = result.rows[0]?.last_attempt;

        // Limite absolue: 5 renvois par heure
        if (attemptCount >= 5) {
            logger.warn('OTP resend rate limit exceeded', {
                userId,
                attempts: attemptCount,
            });

            return res.status(429).json({
                error: 'Trop de demandes de renvoi. Veuillez réessayer dans 1 heure',
            });
        }

        // Délai exponentiel: 30s, 1min, 2min, 4min, 8min
        if (lastAttempt) {
            const delays = [30, 60, 120, 240, 480]; // secondes
            const requiredDelay = delays[Math.min(attemptCount, delays.length - 1)] * 1000;
            const timeSinceLastAttempt = Date.now() - new Date(lastAttempt).getTime();

            if (timeSinceLastAttempt < requiredDelay) {
                const waitSeconds = Math.ceil((requiredDelay - timeSinceLastAttempt) / 1000);

                logger.warn('OTP resend too soon', {
                    userId,
                    waitSeconds,
                });

                return res.status(429).json({
                    error: `Veuillez attendre ${waitSeconds} secondes avant de renvoyer un nouveau code`,
                });
            }
        }

        // Enregistrer cette tentative
        await db.query(
            `INSERT INTO verification_attempts (user_id, attempt_type) VALUES ($1, $2)`,
            [userId, 'resend']
        );

        next();
    } catch (err) {
        logger.error('OTP resend limiter error', { error: err.message });
        // En cas d'erreur, laisser passer
        next();
    }
}

/**
 * Nettoie les anciennes tentatives (> 24h)
 * À appeler périodiquement via cron
 */
async function cleanupOldAttempts() {
    try {
        const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

        const result = await db.query(
            `DELETE FROM verification_attempts WHERE created_at < $1`,
            [oneDayAgo]
        );

        logger.info('Cleaned up old verification attempts', {
            deleted: result.rowCount,
        });
    } catch (err) {
        logger.error('Cleanup verification attempts error', { error: err.message });
    }
}

module.exports = {
    otpVerificationLimiter,
    otpResendLimiter,
    cleanupOldAttempts,
};
