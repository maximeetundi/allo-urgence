const admin = require('firebase-admin');
const db = require('../db/pg_connection');
const logger = require('../utils/logger');

// Initialize Firebase Admin (only if credentials are provided)
let firebaseInitialized = false;

try {
    if (process.env.FIREBASE_PROJECT_ID) {
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId: process.env.FIREBASE_PROJECT_ID,
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
            }),
        });
        firebaseInitialized = true;
        logger.info('Firebase Admin initialized');
    } else {
        logger.warn('Firebase credentials not configured - push notifications disabled');
    }
} catch (err) {
    logger.error('Firebase initialization failed', { error: err.message });
}

/**
 * Register device token for push notifications
 */
async function registerDeviceToken(userId, token, platform = 'android') {
    try {
        // Check if token already exists
        const existing = await db.findOne('device_tokens', { user_id: userId, token });

        if (existing) {
            // Update last_used
            await db.update('device_tokens', existing.id, {
                last_used: new Date(),
                platform,
            });
            logger.info('Device token updated', { userId, platform });
        } else {
            // Insert new token
            await db.insert('device_tokens', {
                user_id: userId,
                token,
                platform,
                last_used: new Date(),
            });
            logger.info('Device token registered', { userId, platform });
        }

        return { success: true };
    } catch (err) {
        logger.error('Error registering device token', { error: err.message });
        throw err;
    }
}

/**
 * Send push notification to user
 */
async function sendNotification(userId, notification) {
    if (!firebaseInitialized) {
        logger.warn('Firebase not initialized - skipping notification');
        return { success: false, reason: 'Firebase not configured' };
    }

    try {
        // Get user's device tokens
        const tokens = await db.query(
            `SELECT token FROM device_tokens WHERE user_id = $1 AND last_used > NOW() - INTERVAL '30 days'`,
            [userId]
        );

        if (tokens.rows.length === 0) {
            logger.warn('No device tokens found for user', { userId });
            return { success: false, reason: 'No device tokens' };
        }

        const deviceTokens = tokens.rows.map(r => r.token);

        // Prepare notification payload
        const message = {
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: notification.data || {},
            tokens: deviceTokens,
        };

        // Add Android-specific config
        message.android = {
            priority: 'high',
            notification: {
                sound: 'default',
                channelId: 'allo_urgence_notifications',
            },
        };

        // Add iOS-specific config
        message.apns = {
            payload: {
                aps: {
                    sound: 'default',
                    badge: 1,
                },
            },
        };

        // Send notification
        const response = await admin.messaging().sendEachForMultitoken(message);

        logger.info('Push notification sent', {
            userId,
            successCount: response.successCount,
            failureCount: response.failureCount,
        });

        // Remove invalid tokens
        if (response.failureCount > 0) {
            const invalidTokens = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success && resp.error?.code === 'messaging/invalid-registration-token') {
                    invalidTokens.push(deviceTokens[idx]);
                }
            });

            if (invalidTokens.length > 0) {
                await db.query(
                    `DELETE FROM device_tokens WHERE token = ANY($1)`,
                    [invalidTokens]
                );
                logger.info('Removed invalid tokens', { count: invalidTokens.length });
            }
        }

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
        };
    } catch (err) {
        logger.error('Error sending push notification', { error: err.message });
        throw err;
    }
}

/**
 * Send "Your turn is approaching" notification
 */
async function sendTurnApproachingNotification(ticket) {
    const notification = {
        title: '🔔 Votre tour approche',
        body: `Vous passerez dans environ ${ticket.estimated_wait_minutes} minutes. Préparez-vous à vous présenter.`,
        data: {
            type: 'turn_approaching',
            ticketId: ticket.id,
            estimatedWaitMinutes: String(ticket.estimated_wait_minutes),
        },
    };

    return sendNotification(ticket.patient_id, notification);
}

/**
 * Send "Please present yourself" notification
 */
async function sendPresentYourselfNotification(ticket) {
    const notification = {
        title: '🚨 Présentez-vous maintenant',
        body: 'C\'est votre tour! Veuillez vous présenter à l\'accueil immédiatement.',
        data: {
            type: 'present_now',
            ticketId: ticket.id,
        },
    };

    return sendNotification(ticket.patient_id, notification);
}

/**
 * Send priority changed notification
 */
async function sendPriorityChangedNotification(ticket, oldPriority, newPriority) {
    const priorityLabels = {
        1: 'P1 — Réanimation',
        2: 'P2 — Très urgent',
        3: 'P3 — Urgent',
        4: 'P4 — Moins urgent',
        5: 'P5 — Non urgent',
    };

    const notification = {
        title: '⚠️ Priorité modifiée',
        body: `Votre priorité a été changée de ${priorityLabels[oldPriority]} à ${priorityLabels[newPriority]}`,
        data: {
            type: 'priority_changed',
            ticketId: ticket.id,
            oldPriority: String(oldPriority),
            newPriority: String(newPriority),
        },
    };

    return sendNotification(ticket.patient_id, notification);
}

/**
 * Send status changed notification
 */
async function sendStatusChangedNotification(ticket, newStatus) {
    const statusLabels = {
        waiting: 'En attente',
        checked_in: 'Enregistré',
        triage: 'En triage',
        in_progress: 'En cours de traitement',
        treated: 'Traité',
        completed: 'Terminé',
    };

    const notification = {
        title: '📋 Statut mis à jour',
        body: `Votre statut: ${statusLabels[newStatus] || newStatus}`,
        data: {
            type: 'status_changed',
            ticketId: ticket.id,
            status: newStatus,
        },
    };

    return sendNotification(ticket.patient_id, notification);
}

/**
 * Notify all staff (nurses, doctors) of a hospital
 */
async function notifyHospitalStaff(hospitalId, title, body, data = {}) {
    if (!firebaseInitialized) return;

    try {
        // Get all staff user IDs for this hospital
        const staff = await db.query(
            `SELECT user_id FROM hospital_staff WHERE hospital_id = $1`,
            [hospitalId]
        );

        if (staff.rows.length === 0) return;

        const userIds = staff.rows.map(r => r.user_id);

        // Get tokens for these users
        const tokensResult = await db.query(
            `SELECT token FROM device_tokens WHERE user_id = ANY($1) AND last_used > NOW() - INTERVAL '30 days'`,
            [userIds]
        );

        if (tokensResult.rows.length === 0) return;

        const tokens = tokensResult.rows.map(r => r.token);

        // Prepare message
        const message = {
            notification: { title, body },
            data,
            tokens,
            android: {
                priority: 'high',
                notification: { sound: 'default', channelId: 'allo_urgence_staff' },
            },
            apns: {
                payload: { aps: { sound: 'default', badge: 1 } },
            },
        };

        const response = await admin.messaging().sendEachForMultitoken(message);
        logger.info('Staff notification sent', {
            hospitalId,
            success: response.successCount,
            failure: response.failureCount
        });

    } catch (err) {
        logger.error('Staff notification error', { error: err.message });
        // Don't throw, just log
    }
}

module.exports = {
    registerDeviceToken,
    sendNotification,
    sendTurnApproachingNotification,
    sendPresentYourselfNotification,
    sendPriorityChangedNotification,
    sendStatusChangedNotification,
    notifyHospitalStaff,
};
