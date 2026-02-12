const express = require('express');
const { v4: uuidv4 } = require('uuid');
const QRCode = require('qrcode');
const db = require('../db/connection');
const { authenticateToken, requireRole, auditLog } = require('../middleware/auth');
const { TRIAGE_CATEGORIES, FOLLOW_UP_QUESTIONS, calculatePriority, getEstimatedWait } = require('../services/triage.service');
const { recalculateAllPositions, getQueueSummary } = require('../services/queue.service');

const router = express.Router();

// GET /api/tickets/triage-categories
router.get('/triage-categories', (req, res) => {
    res.json({ categories: TRIAGE_CATEGORIES, followUpQuestions: FOLLOW_UP_QUESTIONS });
});

// POST /api/tickets — Create ticket
router.post('/', authenticateToken, async (req, res) => {
    try {
        const { hospital_id, category_id, triage_answers } = req.body;
        if (!hospital_id || !category_id) {
            return res.status(400).json({ error: 'hospital_id et category_id sont requis' });
        }

        // Check existing active ticket
        const existing = db.findOne('tickets', t =>
            t.patient_id === req.user.id && ['waiting', 'checked_in', 'triage', 'in_progress'].includes(t.status)
        );
        if (existing) {
            return res.status(409).json({ error: 'Vous avez déjà un ticket actif', ticketId: existing.id });
        }

        const result = calculatePriority(category_id, triage_answers || {});
        const id = uuidv4();
        const sharedToken = uuidv4().substring(0, 8);
        const qrData = JSON.stringify({ ticketId: id, patientId: req.user.id });
        const qrCode = await QRCode.toDataURL(qrData);

        const ticket = db.insert('tickets', {
            id, patient_id: req.user.id, hospital_id,
            priority_level: result.priority,
            validated_priority: null,
            pre_triage_answers: triage_answers || {},
            pre_triage_category: category_id,
            status: 'waiting',
            queue_position: null,
            estimated_wait_minutes: null,
            qr_code: qrCode,
            assigned_room: null,
            shared_token: sharedToken,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        });

        recalculateAllPositions(hospital_id);

        // Refresh ticket with position
        const updated = db.findById('tickets', id);

        auditLog('create_ticket', req.user.id, { ticketId: id, priority: result.priority, category: category_id });

        const io = req.app.get('io');
        if (io) {
            io.to(`hospital:${hospital_id}`).emit('queue_update', getQueueSummary(hospital_id));
            io.to(`hospital:${hospital_id}`).emit('new_ticket', { ticketId: id, priority: result.priority, category: result.category });
        }

        res.status(201).json({
            ticket: {
                id: updated.id, priority_level: updated.priority_level,
                estimated_priority_label: result.category,
                status: updated.status, queue_position: updated.queue_position,
                estimated_wait_minutes: updated.estimated_wait_minutes,
                qr_code: updated.qr_code, shared_token: updated.shared_token
            },
            disclaimer: result.disclaimer
        });
    } catch (err) {
        console.error('Create ticket error:', err);
        res.status(500).json({ error: 'Erreur serveur' });
    }
});

// GET /api/tickets/patient/active
router.get('/patient/active', authenticateToken, (req, res) => {
    const ticket = db.findOne('tickets', t =>
        t.patient_id === req.user.id && ['waiting', 'checked_in', 'triage', 'in_progress'].includes(t.status)
    );
    res.json({ ticket: ticket || null });
});

// GET /api/tickets/patient/history
router.get('/patient/history', authenticateToken, (req, res) => {
    const tickets = db.findMany('tickets', t => t.patient_id === req.user.id)
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
        .slice(0, 20);
    res.json({ tickets });
});

// GET /api/tickets/queue/:hospitalId — Nurse/Doctor view
router.get('/queue/:hospitalId', authenticateToken, requireRole('nurse', 'doctor', 'admin'), (req, res) => {
    const tickets = db.findMany('tickets', t =>
        t.hospital_id === req.params.hospitalId && ['waiting', 'checked_in', 'triage', 'in_progress'].includes(t.status)
    ).sort((a, b) => {
        const pa = a.validated_priority || a.priority_level;
        const pb = b.validated_priority || b.priority_level;
        if (pa !== pb) return pa - pb;
        return new Date(a.created_at) - new Date(b.created_at);
    }).map(t => {
        const patient = db.findById('users', t.patient_id);
        return {
            ...t,
            patient_nom: patient?.nom, patient_prenom: patient?.prenom,
            patient_telephone: patient?.telephone, allergies: patient?.allergies,
            conditions_medicales: patient?.conditions_medicales,
            date_naissance: patient?.date_naissance
        };
    });

    res.json({ tickets, summary: getQueueSummary(req.params.hospitalId) });
});

// GET /api/tickets/:id — Ticket details
router.get('/:id', authenticateToken, (req, res) => {
    const ticket = db.findById('tickets', req.params.id);
    if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

    if (req.user.role === 'patient' && ticket.patient_id !== req.user.id) {
        return res.status(403).json({ error: 'Accès non autorisé' });
    }

    const patient = db.findById('users', ticket.patient_id);
    const triageNotes = db.findMany('triage_notes', tn => tn.ticket_id === req.params.id)
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    const doctorNotes = db.findMany('doctor_notes', dn => dn.ticket_id === req.params.id)
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    res.json({
        ...ticket,
        patient_nom: patient?.nom, patient_prenom: patient?.prenom,
        patient_telephone: patient?.telephone, ramq_number: patient?.ramq_number,
        allergies: patient?.allergies, conditions_medicales: patient?.conditions_medicales,
        medicaments: patient?.medicaments, date_naissance: patient?.date_naissance,
        triageNotes, doctorNotes
    });
});

// PATCH /api/tickets/:id/checkin
router.patch('/:id/checkin', authenticateToken, (req, res) => {
    const ticket = db.findById('tickets', req.params.id);
    if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });
    if (ticket.patient_id !== req.user.id && req.user.role === 'patient') {
        return res.status(403).json({ error: 'Accès non autorisé' });
    }

    db.update('tickets', req.params.id, { status: 'checked_in' });

    const io = req.app.get('io');
    if (io) {
        io.to(`hospital:${ticket.hospital_id}`).emit('patient_checkin', { ticketId: ticket.id });
        io.to(`hospital:${ticket.hospital_id}`).emit('queue_update', getQueueSummary(ticket.hospital_id));
    }

    res.json({ message: 'Check-in effectué', status: 'checked_in' });
});

// PATCH /api/tickets/:id/triage — Nurse validates priority
router.patch('/:id/triage', authenticateToken, requireRole('nurse', 'admin'), (req, res) => {
    const { validated_priority, notes } = req.body;
    if (!validated_priority || validated_priority < 1 || validated_priority > 5) {
        return res.status(400).json({ error: 'Priorité validée requise (1-5)' });
    }

    const ticket = db.findById('tickets', req.params.id);
    if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

    db.update('tickets', req.params.id, { validated_priority, status: 'triage' });

    db.insert('triage_notes', {
        id: uuidv4(), ticket_id: req.params.id, nurse_id: req.user.id,
        validated_priority, notes: notes || null,
        created_at: new Date().toISOString()
    });

    recalculateAllPositions(ticket.hospital_id);
    auditLog('triage_validation', req.user.id, { ticketId: req.params.id, from: ticket.priority_level, to: validated_priority });

    const io = req.app.get('io');
    if (io) {
        io.to(`hospital:${ticket.hospital_id}`).emit('queue_update', getQueueSummary(ticket.hospital_id));
        io.to(`ticket:${ticket.id}`).emit('ticket_update', { status: 'triage', validated_priority });
        if (validated_priority <= 2) {
            io.to(`hospital:${ticket.hospital_id}`).emit('critical_alert', { ticketId: ticket.id, priority: validated_priority });
        }
    }

    res.json({ message: 'Triage effectué', validated_priority });
});

// PATCH /api/tickets/:id/assign-room
router.patch('/:id/assign-room', authenticateToken, requireRole('nurse', 'admin'), (req, res) => {
    const { room } = req.body;
    if (!room) return res.status(400).json({ error: 'Numéro de salle requis' });

    const ticket = db.findById('tickets', req.params.id);
    if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

    db.update('tickets', req.params.id, { assigned_room: room, status: 'in_progress' });
    recalculateAllPositions(ticket.hospital_id);

    const io = req.app.get('io');
    if (io) {
        io.to(`hospital:${ticket.hospital_id}`).emit('queue_update', getQueueSummary(ticket.hospital_id));
        io.to(`ticket:${ticket.id}`).emit('ticket_update', { status: 'in_progress', assigned_room: room });
    }

    res.json({ message: `Salle ${room} assignée`, room });
});

// PATCH /api/tickets/:id/treat — Doctor marks treated
router.patch('/:id/treat', authenticateToken, requireRole('doctor', 'admin'), (req, res) => {
    const { notes, diagnosis } = req.body;
    const ticket = db.findById('tickets', req.params.id);
    if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

    db.update('tickets', req.params.id, { status: 'treated' });

    if (notes || diagnosis) {
        db.insert('doctor_notes', {
            id: uuidv4(), ticket_id: req.params.id, doctor_id: req.user.id,
            notes: notes || null, diagnosis: diagnosis || null,
            created_at: new Date().toISOString()
        });
    }

    recalculateAllPositions(ticket.hospital_id);

    const io = req.app.get('io');
    if (io) {
        io.to(`hospital:${ticket.hospital_id}`).emit('queue_update', getQueueSummary(ticket.hospital_id));
        io.to(`ticket:${ticket.id}`).emit('ticket_update', { status: 'treated' });
    }

    res.json({ message: 'Patient marqué comme traité' });
});

// POST /api/tickets/:id/doctor-note
router.post('/:id/doctor-note', authenticateToken, requireRole('doctor', 'admin'), (req, res) => {
    const { notes, diagnosis } = req.body;
    const ticket = db.findById('tickets', req.params.id);
    if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

    db.insert('doctor_notes', {
        id: uuidv4(), ticket_id: req.params.id, doctor_id: req.user.id,
        notes: notes || null, diagnosis: diagnosis || null,
        created_at: new Date().toISOString()
    });

    res.json({ message: 'Note ajoutée' });
});

// GET /api/tickets/shared/:token — Public share link
router.get('/shared/:token', (req, res) => {
    const ticket = db.findOne('tickets', t => t.shared_token === req.params.token);
    if (!ticket) return res.status(404).json({ error: 'Lien de partage invalide' });

    const hospital = db.findById('hospitals', ticket.hospital_id);

    res.json({
        status: ticket.status, queue_position: ticket.queue_position,
        estimated_wait_minutes: ticket.estimated_wait_minutes,
        hospital_name: hospital?.name, assigned_room: ticket.assigned_room
    });
});

module.exports = router;
