const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const db = require('../db/pg_connection');
const { authenticateToken, requireRole, auditLog } = require('../middleware/auth');
const { recalculateQueue, getQueueSummary } = require('../services/queue.service');
const triageService = require('../services/triage.service');
const { calculatePriority } = require('../config/triage');

// ── GET /api/tickets/triage-categories ──────────────────────────
router.get('/triage-categories', (req, res) => {
    res.json({
        categories: triageService.getCategories(),
        followUpQuestions: triageService.getFollowUpQuestions(),
    });
});

// ── POST /api/tickets — create a new ticket ─────────────────────
router.post('/', authenticateToken, async (req, res) => {
    try {
        const { hospital_id, category_id, triage_answers } = req.body;

        if (!hospital_id) {
            return res.status(400).json({ error: 'hospital_id requis' });
        }

        const hospital = await db.findById('hospitals', hospital_id);
        if (!hospital) return res.status(404).json({ error: 'Hôpital non trouvé' });

        // Check for existing active ticket
        const existing = await db.findOne('tickets', { patient_id: req.user.id, status: 'waiting' });
        if (existing) {
            return res.status(409).json({ error: 'Vous avez déjà un ticket actif', ticket: existing });
        }

        // Calculate priority from new triage system
        // Calculate priority
        let estimatedPriority = 5; // Default

        if (category_id) {
            // Use triageService which matches frontend questions
            const result = triageService.calculatePriority(category_id, triage_answers || {});
            estimatedPriority = result.priority || 5;
        } else if (triage_answers && Object.keys(triage_answers).length > 0) {
            // Use new config/triage system as fallback
            const result = calculatePriority(triage_answers);
            estimatedPriority = result.priority || 5;
        }

        // Get patient info
        const patient = await db.findById('users', req.user.id);

        const ticket = await db.insert('tickets', {
            patient_id: req.user.id,
            hospital_id,
            priority_level: estimatedPriority,
            estimated_priority: estimatedPriority,
            status: 'waiting',
            code: 'T' + uuidv4().split('-')[0].toUpperCase(), // Simple code generation
            pre_triage_category: category_id || 'triage_questionnaire',
            triage_answers: JSON.stringify(triage_answers || {}),
            shared_token: uuidv4().slice(0, 8).toUpperCase(),
            patient_nom: patient?.nom || '',
            patient_prenom: patient?.prenom || '',
            patient_telephone: patient?.telephone || null,
            allergies: patient?.allergies || null,
            conditions_medicales: patient?.conditions_medicales || null,
            date_naissance: patient?.date_naissance || null,
        });

        await recalculateQueue(hospital_id);

        // Refresh ticket with queue position
        const updated = await db.findById('tickets', ticket.id);

        // Socket notifications
        const io = req.app.get('io');
        if (io) {
            io.to(`hospital_${hospital_id}`).emit('new_ticket', updated);
            if (estimatedPriority <= 2) {
                io.to(`hospital_${hospital_id}`).emit('critical_alert', {
                    ticketId: updated.id,
                    priority: estimatedPriority,
                    patientName: `${patient?.prenom} ${patient?.nom}`,
                });
            }
        }

        auditLog('ticket_created', req.user.id, { ticketId: updated.id, priority: estimatedPriority });
        res.status(201).json({ ticket: updated });
    } catch (err) {
        console.error('Create ticket error:', err.message);
        res.status(500).json({ error: 'Erreur lors de la création du ticket' });
    }
});

// ── GET /api/tickets/patient/active ─────────────────────────────
router.get('/patient/active', authenticateToken, async (req, res) => {
    try {
        const result = await db.query(
            `SELECT * FROM tickets
       WHERE patient_id = $1 AND status IN ('waiting','checked_in','triage','in_progress')
       ORDER BY created_at DESC LIMIT 1`,
            [req.user.id],
        );
        res.json({ ticket: result.rows[0] || null });
    } catch (err) {
        console.error('Active ticket error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── GET /api/tickets/patient/history ────────────────────────────
router.get('/patient/history', authenticateToken, async (req, res) => {
    try {
        const result = await db.query(
            `SELECT * FROM tickets WHERE patient_id = $1 ORDER BY created_at DESC LIMIT 20`,
            [req.user.id],
        );
        res.json({ tickets: result.rows });
    } catch (err) {
        console.error('History error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── GET /api/tickets/queue/:hospitalId ──────────────────────────
router.get('/queue/:hospitalId', authenticateToken, requireRole('nurse', 'doctor', 'admin'), async (req, res) => {
    try {
        const result = await db.query(
            `SELECT * FROM tickets
       WHERE hospital_id = $1 AND status IN ('waiting','checked_in','triage','in_progress')
       ORDER BY COALESCE(validated_priority, priority_level) ASC, created_at ASC`,
            [req.params.hospitalId],
        );
        const summary = await getQueueSummary(req.params.hospitalId);
        res.json({ tickets: result.rows, summary });
    } catch (err) {
        console.error('Queue error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── GET /api/tickets/:id ────────────────────────────────────────
router.get('/:id', authenticateToken, async (req, res) => {
    try {
        const ticket = await db.findById('tickets', req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });
        res.json(ticket);
    } catch (err) {
        console.error('Ticket detail error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── PATCH /api/tickets/:id/checkin ──────────────────────────────
router.patch('/:id/checkin', authenticateToken, async (req, res) => {
    try {
        const ticket = await db.findById('tickets', req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

        const updated = await db.update('tickets', ticket.id, { status: 'checked_in' });

        const io = req.app.get('io');
        if (io) {
            io.to(`hospital_${ticket.hospital_id}`).emit('patient_checkin', updated);
            io.to(`ticket_${ticket.id}`).emit('ticket_update', updated);
        }

        res.json(updated);
    } catch (err) {
        console.error('Checkin error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── PATCH /api/tickets/:id/triage ───────────────────────────────
router.patch('/:id/triage', authenticateToken, requireRole('nurse', 'admin'), async (req, res) => {
    try {
        const { validated_priority, notes } = req.body;
        const ticket = await db.findById('tickets', req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

        const updated = await db.update('tickets', ticket.id, {
            validated_priority,
            status: 'triage',
        });

        if (notes) {
            await db.insert('triage_notes', {
                ticket_id: ticket.id,
                nurse_id: req.user.id,
                validated_priority,
                notes,
            });
        }

        await recalculateQueue(ticket.hospital_id);
        const refreshed = await db.findById('tickets', ticket.id);

        const io = req.app.get('io');
        if (io) {
            io.to(`hospital_${ticket.hospital_id}`).emit('queue_update', await getQueueSummary(ticket.hospital_id));
            io.to(`ticket_${ticket.id}`).emit('ticket_update', refreshed);
        }

        auditLog('ticket_triaged', req.user.id, { ticketId: ticket.id, validated_priority });
        res.json(refreshed);
    } catch (err) {
        console.error('Triage error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── PATCH /api/tickets/:id/assign-room ──────────────────────────
router.patch('/:id/assign-room', authenticateToken, requireRole('nurse', 'admin'), async (req, res) => {
    try {
        const { room } = req.body;
        const ticket = await db.findById('tickets', req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

        const updated = await db.update('tickets', ticket.id, {
            assigned_room: room,
            status: 'in_progress',
        });

        const io = req.app.get('io');
        if (io) {
            io.to(`ticket_${ticket.id}`).emit('ticket_update', updated);
            io.to(`hospital_${ticket.hospital_id}`).emit('queue_update', await getQueueSummary(ticket.hospital_id));
        }

        res.json(updated);
    } catch (err) {
        console.error('Assign room error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── PATCH /api/tickets/:id/treat ────────────────────────────────
router.patch('/:id/treat', authenticateToken, requireRole('doctor', 'admin'), async (req, res) => {
    try {
        const { notes, diagnosis } = req.body;
        const ticket = await db.findById('tickets', req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

        const updated = await db.update('tickets', ticket.id, { status: 'treated' });

        if (notes || diagnosis) {
            await db.insert('doctor_notes', {
                ticket_id: ticket.id,
                doctor_id: req.user.id,
                notes: notes || null,
                diagnosis: diagnosis || null,
            });
        }

        await recalculateQueue(ticket.hospital_id);

        const io = req.app.get('io');
        if (io) {
            io.to(`ticket_${ticket.id}`).emit('ticket_update', updated);
            io.to(`hospital_${ticket.hospital_id}`).emit('queue_update', await getQueueSummary(ticket.hospital_id));
        }

        auditLog('ticket_treated', req.user.id, { ticketId: ticket.id });
        res.json(updated);
    } catch (err) {
        console.error('Treat error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── POST /api/tickets/:id/doctor-note ───────────────────────────
router.post('/:id/doctor-note', authenticateToken, requireRole('doctor', 'admin'), async (req, res) => {
    try {
        const { notes, diagnosis } = req.body;
        const ticket = await db.findById('tickets', req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

        const note = await db.insert('doctor_notes', {
            ticket_id: ticket.id,
            doctor_id: req.user.id,
            notes: notes || null,
            diagnosis: diagnosis || null,
        });

        res.status(201).json(note);
    } catch (err) {
        console.error('Doctor note error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// ── GET /api/tickets/shared/:token ──────────────────────────────
router.get('/shared/:token', async (req, res) => {
    try {
        const ticket = await db.findOne('tickets', { shared_token: req.params.token });
        if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });
        // Return limited info
        res.json({
            status: ticket.status,
            queue_position: ticket.queue_position,
            estimated_wait_minutes: ticket.estimated_wait_minutes,
            priority_level: ticket.validated_priority || ticket.priority_level,
            assigned_room: ticket.assigned_room,
        });
    } catch (err) {
        console.error('Shared ticket error:', err.message);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

module.exports = router;
