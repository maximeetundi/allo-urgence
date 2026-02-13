const express = require('express');
const router = express.Router();
const db = require('../db/pg_connection');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { recalculateQueue } = require('../services/queue.service');
const { emitToHospital, emitToTicket, emitCriticalAlert } = require('../services/websocket.service');
const { sendPriorityChangedNotification } = require('../services/notification.service');

// ── GET /api/nurse/patients ────────────────────────────────────
// Liste des patients pour infirmier (triée par priorité)
router.get('/patients', authenticateToken, requireRole(['nurse', 'admin']), async (req, res) => {
    try {
        const { hospital_id, status, priority } = req.query;

        let query = `
      SELECT 
        t.*,
        u.nom as patient_nom,
        u.prenom as patient_prenom,
        u.date_naissance as patient_dob,
        u.telephone as patient_phone,
        h.name as hospital_name
      FROM tickets t
      JOIN users u ON t.patient_id = u.id
      JOIN hospitals h ON t.hospital_id = h.id
      WHERE 1=1
    `;

        const params = [];
        let paramIndex = 1;

        const userHospitalIds = req.user.hospital_ids || [];

        // Determine effective hospital ID
        let targetHospitalId = hospital_id;

        // If hospital_id provided, verify access
        if (targetHospitalId) {
            if (!userHospitalIds.includes(targetHospitalId) && req.user.role !== 'admin') {
                return res.status(403).json({ error: 'Accès non autorisé à cet hôpital' });
            }
        } else {
            // Default to first assigned hospital if available
            if (userHospitalIds.length > 0) {
                targetHospitalId = userHospitalIds[0];
            } else if (req.user.role === 'admin') {
                // Admin without specific hospital
            }
        }

        // Filter by hospital
        if (targetHospitalId) {
            query += ` AND t.hospital_id = $${paramIndex}`;
            params.push(targetHospitalId);
            paramIndex++;
        }

        // Filter by status
        if (status) {
            query += ` AND t.status = $${paramIndex}`;
            params.push(status);
            paramIndex++;
        } else {
            // Par défaut, exclure les tickets terminés
            query += ` AND t.status NOT IN ('treated', 'completed', 'cancelled')`;
        }

        // Filter by priority
        if (priority) {
            query += ` AND t.priority_level = $${paramIndex}`;
            params.push(priority);
            paramIndex++;
        }

        // Tri par priorité (P1 en premier) puis par temps d'attente
        query += ` ORDER BY t.priority_level ASC, t.created_at ASC`;

        const result = await db.query(query, params);

        // Statistiques
        const statsQuery = `
      SELECT 
        COUNT(*) FILTER (WHERE priority_level = 1) as p1_count,
        COUNT(*) FILTER (WHERE priority_level = 2) as p2_count,
        COUNT(*) FILTER (WHERE priority_level = 3) as p3_count,
        COUNT(*) FILTER (WHERE priority_level = 4) as p4_count,
        COUNT(*) FILTER (WHERE priority_level = 5) as p5_count,
        COUNT(*) FILTER (WHERE status = 'waiting') as waiting_count,
        COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_count,
        AVG(estimated_wait_minutes) as avg_wait_time
      FROM tickets
      WHERE hospital_id = $1 AND status NOT IN ('completed', 'cancelled')
    `;

        // Only run stats if we have a target hospital
        let stats = {};
        if (targetHospitalId) {
            const statsResult = await db.query(statsQuery, [targetHospitalId]);
            stats = statsResult.rows[0];
        }

        res.json({
            patients: result.rows,
            stats: stats,
            total: result.rows.length,
        });
    } catch (error) {
        console.error('Error fetching nurse patients:', error);
        res.status(500).json({ error: 'Erreur lors de la récupération des patients' });
    }
});

// ── POST /api/nurse/triage/validate ────────────────────────────
// Validation rapide du triage par infirmier
router.post('/triage/validate', authenticateToken, requireRole(['nurse', 'admin']), async (req, res) => {
    try {
        const { ticket_id, validated_priority, assigned_room, justification } = req.body;

        // Validation
        if (!ticket_id || !validated_priority) {
            return res.status(400).json({ error: 'ticket_id et validated_priority requis' });
        }

        if (validated_priority < 1 || validated_priority > 5) {
            return res.status(400).json({ error: 'validated_priority doit être entre 1 et 5' });
        }

        // Récupérer le ticket actuel
        const ticketResult = await db.query(
            'SELECT * FROM tickets WHERE id = $1',
            [ticket_id]
        );

        if (ticketResult.rows.length === 0) {
            return res.status(404).json({ error: 'Ticket non trouvé' });
        }

        const oldTicket = ticketResult.rows[0];
        const oldPriority = oldTicket.priority_level;

        // Mettre à jour le ticket
        const updateQuery = `
      UPDATE tickets
      SET 
        validated_priority = $1,
        priority_level = $1,
        assigned_room = $2,
        triage_justification = $3,
        triaged_by = $4,
        triaged_at = CURRENT_TIMESTAMP,
        status = CASE 
          WHEN status = 'waiting' AND $2 IS NOT NULL THEN 'in_progress'
          ELSE status
        END,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $5
      RETURNING *
    `;

        const result = await db.query(updateQuery, [
            validated_priority,
            assigned_room || null,
            justification || null,
            req.user.id,
            ticket_id,
        ]);

        const updatedTicket = result.rows[0];

        // Recalculer la file d'attente
        await recalculateQueue(updatedTicket.hospital_id);

        // Émettre événement WebSocket
        emitToTicket(ticket_id, 'ticket_update', updatedTicket);
        emitToHospital(updatedTicket.hospital_id, 'queue_update', {
            hospital_id: updatedTicket.hospital_id,
            timestamp: new Date(),
        });

        // Si priorité changée, envoyer notification
        if (oldPriority !== validated_priority) {
            await sendPriorityChangedNotification(updatedTicket, oldPriority, validated_priority);

            // Si nouveau P1 ou P2, alerte critique
            if (validated_priority <= 2) {
                emitCriticalAlert(updatedTicket.hospital_id, {
                    type: 'high_priority_patient',
                    ticket: updatedTicket,
                    priority: validated_priority,
                    message: `Patient P${validated_priority} nécessite attention immédiate`,
                });
            }
        }

        res.json({
            ticket: updatedTicket,
            message: 'Triage validé avec succès',
        });
    } catch (error) {
        console.error('Error validating triage:', error);
        res.status(500).json({ error: 'Erreur lors de la validation du triage' });
    }
});

// ── GET /api/nurse/rooms/available ─────────────────────────────
// Liste des salles disponibles
router.get('/rooms/available', authenticateToken, requireRole(['nurse', 'admin']), async (req, res) => {
    try {
        const { hospital_id } = req.query;

        if (!hospital_id) {
            return res.status(400).json({ error: 'hospital_id requis' });
        }

        // Récupérer toutes les salles occupées
        const occupiedQuery = `
      SELECT DISTINCT assigned_room
      FROM tickets
      WHERE hospital_id = $1 
        AND assigned_room IS NOT NULL
        AND status IN ('waiting', 'in_progress')
    `;

        const occupiedResult = await db.query(occupiedQuery, [hospital_id]);
        const occupiedRooms = occupiedResult.rows.map(r => r.assigned_room);

        // Liste des salles (à adapter selon votre configuration)
        const allRooms = [
            'Salle 1', 'Salle 2', 'Salle 3', 'Salle 4', 'Salle 5',
            'Salle 6', 'Salle 7', 'Salle 8', 'Salle 9', 'Salle 10',
            'Trauma 1', 'Trauma 2', 'Pédiatrie 1', 'Pédiatrie 2',
        ];

        const availableRooms = allRooms.filter(room => !occupiedRooms.includes(room));

        res.json({
            available: availableRooms,
            occupied: occupiedRooms,
            total: allRooms.length,
            available_count: availableRooms.length,
        });
    } catch (error) {
        console.error('Error fetching available rooms:', error);
        res.status(500).json({ error: 'Erreur lors de la récupération des salles' });
    }
});

// ── GET /api/nurse/alerts ──────────────────────────────────────
// Alertes critiques actives
router.get('/alerts', authenticateToken, requireRole(['nurse', 'admin']), async (req, res) => {
    try {
        const { hospital_id } = req.query;

        const query = `
      SELECT 
        t.*,
        u.nom as patient_nom,
        u.prenom as patient_prenom,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - t.created_at))/60 as waiting_minutes
      FROM tickets t
      JOIN users u ON t.patient_id = u.id
      WHERE t.hospital_id = $1
        AND t.priority_level <= 2
        AND t.status IN ('waiting', 'in_progress')
      ORDER BY t.priority_level ASC, t.created_at ASC
    `;

        const result = await db.query(query, [hospital_id]);

        res.json({
            alerts: result.rows,
            count: result.rows.length,
        });
    } catch (error) {
        console.error('Error fetching alerts:', error);
        res.status(500).json({ error: 'Erreur lors de la récupération des alertes' });
    }
});

// ── POST /api/nurse/alert/acknowledge ──────────────────────────
// Marquer une alerte comme prise en charge
router.post('/alert/acknowledge', authenticateToken, requireRole(['nurse', 'admin']), async (req, res) => {
    try {
        const { ticket_id } = req.body;

        if (!ticket_id) {
            return res.status(400).json({ error: 'ticket_id requis' });
        }

        const result = await db.query(
            `UPDATE tickets 
       SET alert_acknowledged = true, 
           alert_acknowledged_by = $1,
           alert_acknowledged_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *`,
            [req.user.id, ticket_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Ticket non trouvé' });
        }

        res.json({
            ticket: result.rows[0],
            message: 'Alerte prise en charge',
        });
    } catch (error) {
        console.error('Error acknowledging alert:', error);
        res.status(500).json({ error: 'Erreur lors de la prise en charge de l\'alerte' });
    }
});

module.exports = router;
