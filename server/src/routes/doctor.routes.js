const express = require('express');
const router = express.Router();
const db = require('../db/pg_connection');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { emitToHospital, emitToTicket } = require('../services/websocket.service');
const { sendStatusChangedNotification } = require('../services/notification.service');

// ── GET /api/doctor/patients ───────────────────────────────────
// Liste des patients pour médecin (triée automatiquement)
router.get('/patients', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
    try {
        const { hospital_id, status } = req.query;

        let query = `
      SELECT 
        t.*,
        u.nom as patient_nom,
        u.prenom as patient_prenom,
        u.date_naissance as patient_dob,
        u.telephone as patient_phone,
        u.email as patient_email,
        EXTRACT(YEAR FROM AGE(u.date_naissance)) as patient_age,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - t.created_at))/60 as waiting_minutes,
        h.name as hospital_name
      FROM tickets t
      JOIN users u ON t.patient_id = u.id
      JOIN hospitals h ON t.hospital_id = h.id
      WHERE 1=1
    `;

        const params = [];
        let paramIndex = 1;

        // Filter by hospital
        if (hospital_id) {
            query += ` AND t.hospital_id = $${paramIndex}`;
            params.push(hospital_id);
            paramIndex++;
        }

        // Filter by status
        if (status) {
            query += ` AND t.status = $${paramIndex}`;
            params.push(status);
            paramIndex++;
        } else {
            // Par défaut, montrer seulement en attente et en cours
            query += ` AND t.status IN ('waiting', 'in_progress')`;
        }

        // Tri automatique: Priorité > Temps d'attente
        query += ` ORDER BY t.priority_level ASC, t.created_at ASC`;

        const result = await db.query(query, params);

        res.json({
            patients: result.rows,
            total: result.rows.length,
        });
    } catch (error) {
        console.error('Error fetching doctor patients:', error);
        res.status(500).json({ error: 'Erreur lors de la récupération des patients' });
    }
});

// ── GET /api/doctor/patient/:id ────────────────────────────────
// Détails complets d'un patient
router.get('/patient/:id', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
    try {
        const { id } = req.params;

        // Informations ticket
        const ticketQuery = `
      SELECT 
        t.*,
        u.nom, u.prenom, u.date_naissance, u.telephone, u.email,
        u.ramq, u.address,
        EXTRACT(YEAR FROM AGE(u.date_naissance)) as age,
        h.name as hospital_name
      FROM tickets t
      JOIN users u ON t.patient_id = u.id
      JOIN hospitals h ON t.hospital_id = h.id
      WHERE t.id = $1
    `;

        const ticketResult = await db.query(ticketQuery, [id]);

        if (ticketResult.rows.length === 0) {
            return res.status(404).json({ error: 'Patient non trouvé' });
        }

        const patient = ticketResult.rows[0];

        // Historique des visites
        const historyQuery = `
      SELECT 
        id, created_at, priority_level, status, assigned_room,
        medical_notes
      FROM tickets
      WHERE patient_id = $1 AND id != $2
      ORDER BY created_at DESC
      LIMIT 5
    `;

        const historyResult = await db.query(historyQuery, [patient.patient_id, id]);

        // Notes médicales du ticket actuel
        const notesQuery = `
      SELECT *
      FROM medical_notes
      WHERE ticket_id = $1
      ORDER BY created_at DESC
    `;

        const notesResult = await db.query(notesQuery, [id]);

        res.json({
            patient,
            history: historyResult.rows,
            notes: notesResult.rows,
        });
    } catch (error) {
        console.error('Error fetching patient details:', error);
        res.status(500).json({ error: 'Erreur lors de la récupération des détails' });
    }
});

// ── POST /api/doctor/patient/:id/status ────────────────────────
// Changer le statut d'un patient
router.post('/patient/:id/status', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const validStatuses = ['waiting', 'in_progress', 'completed', 'cancelled'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({ error: 'Statut invalide' });
        }

        const result = await db.query(
            `UPDATE tickets
       SET status = $1,
           treated_by = $2,
           treated_at = CASE WHEN $1 = 'completed' THEN CURRENT_TIMESTAMP ELSE treated_at END,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
            [status, req.user.id, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Ticket non trouvé' });
        }

        const updatedTicket = result.rows[0];

        // Émettre événement WebSocket
        emitToTicket(id, 'ticket_update', updatedTicket);
        emitToHospital(updatedTicket.hospital_id, 'queue_update', {
            hospital_id: updatedTicket.hospital_id,
            timestamp: new Date(),
        });

        // Notification patient
        await sendStatusChangedNotification(updatedTicket, status);

        res.json({
            ticket: updatedTicket,
            message: 'Statut mis à jour',
        });
    } catch (error) {
        console.error('Error updating status:', error);
        res.status(500).json({ error: 'Erreur lors de la mise à jour du statut' });
    }
});

// ── POST /api/doctor/patient/:id/notes ─────────────────────────
// Ajouter une note médicale
router.post('/patient/:id/notes', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
    try {
        const { id } = req.params;
        const { content, type } = req.body;

        if (!content) {
            return res.status(400).json({ error: 'Contenu de la note requis' });
        }

        const result = await db.query(
            `INSERT INTO medical_notes (ticket_id, doctor_id, content, note_type, created_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
       RETURNING *`,
            [id, req.user.id, content, type || 'general']
        );

        // Mettre à jour le ticket
        await db.query(
            `UPDATE tickets
       SET medical_notes = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
            [content, id]
        );

        res.json({
            note: result.rows[0],
            message: 'Note ajoutée',
        });
    } catch (error) {
        console.error('Error adding note:', error);
        res.status(500).json({ error: 'Erreur lors de l\'ajout de la note' });
    }
});

// ── GET /api/doctor/templates ──────────────────────────────────
// Templates de notes prédéfinies
router.get('/templates', authenticateToken, requireRole(['doctor', 'admin']), async (req, res) => {
    try {
        const templates = [
            {
                id: 'consultation_generale',
                name: 'Consultation générale',
                content: 'Patient vu en consultation.\n\nMotif: \n\nExamen: \n\nDiagnostic: \n\nTraitement: \n\nSuivi: ',
            },
            {
                id: 'trauma_mineur',
                name: 'Trauma mineur',
                content: 'Trauma mineur évalué.\n\nMécanisme: \n\nLésions: \n\nTraitement: \n\nConsignes: ',
            },
            {
                id: 'douleur_abdominale',
                name: 'Douleur abdominale',
                content: 'Douleur abdominale évaluée.\n\nLocalisation: \n\nCaractère: \n\nExamen: \n\nDiagnostic: \n\nPlan: ',
            },
            {
                id: 'fievre',
                name: 'Fièvre',
                content: 'Fièvre évaluée.\n\nTempérature: \n\nSymptômes associés: \n\nExamen: \n\nDiagnostic: \n\nTraitement: ',
            },
            {
                id: 'sortie',
                name: 'Congé',
                content: 'Patient autorisé à quitter.\n\nDiagnostic final: \n\nTraitement prescrit: \n\nConsignes: \n\nSuivi: ',
            },
        ];

        res.json({ templates });
    } catch (error) {
        console.error('Error fetching templates:', error);
        res.status(500).json({ error: 'Erreur lors de la récupération des templates' });
    }
});

module.exports = router;
