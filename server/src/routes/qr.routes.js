const express = require('express');
const router = express.Router();
const db = require('../db/pg_connection');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { validateQRCode } = require('../services/qr.service');
const { emitToTicket, emitToHospital } = require('../services/websocket.service');

// ── POST /api/qr/scan ──────────────────────────────────────────
// Scan QR code to check-in patient
router.post('/scan', authenticateToken, requireRole(['nurse', 'admin']), async (req, res) => {
    try {
        const { qr_data } = req.body;

        if (!qr_data) {
            return res.status(400).json({ error: 'QR data required' });
        }

        // Validate QR code
        const validation = validateQRCode(qr_data);
        if (!validation.valid) {
            return res.status(400).json({ error: validation.error });
        }

        const { ticket_id, hospital_id } = validation;

        // Get ticket
        const ticketResult = await db.query(
            'SELECT * FROM tickets WHERE id = $1 AND hospital_id = $2',
            [ticket_id, hospital_id]
        );

        if (ticketResult.rows.length === 0) {
            return res.status(404).json({ error: 'Ticket not found' });
        }

        const ticket = ticketResult.rows[0];

        // Check if already checked in
        if (ticket.checked_in) {
            return res.status(400).json({
                error: 'Patient already checked in',
                checked_in_at: ticket.checked_in_at,
            });
        }

        // Update ticket
        const updateResult = await db.query(
            `UPDATE tickets
       SET checked_in = true,
           checked_in_at = CURRENT_TIMESTAMP,
           checked_in_by = $1,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *`,
            [req.user.id, ticket_id]
        );

        const updatedTicket = updateResult.rows[0];

        // Emit WebSocket event
        emitToTicket(ticket_id, 'ticket_update', updatedTicket);
        emitToHospital(hospital_id, 'patient_checked_in', {
            ticket_id,
            patient_name: `${ticket.patient_nom} ${ticket.patient_prenom}`,
            timestamp: new Date(),
        });

        res.json({
            success: true,
            ticket: updatedTicket,
            message: 'Patient checked in successfully',
        });
    } catch (error) {
        console.error('Error scanning QR code:', error);
        res.status(500).json({ error: 'Error processing QR code' });
    }
});

// ── GET /api/qr/ticket/:id ─────────────────────────────────────
// Get QR code for ticket (regenerate if needed)
router.get('/ticket/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        // Get ticket
        const result = await db.query(
            'SELECT * FROM tickets WHERE id = $1 AND patient_id = $2',
            [id, req.user.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Ticket not found' });
        }

        const ticket = result.rows[0];

        // Return existing QR code
        if (ticket.qr_code) {
            res.json({
                qr_code: ticket.qr_code,
                checked_in: ticket.checked_in || false,
                checked_in_at: ticket.checked_in_at,
            });
        } else {
            res.status(404).json({ error: 'QR code not found' });
        }
    } catch (error) {
        console.error('Error getting QR code:', error);
        res.status(500).json({ error: 'Error retrieving QR code' });
    }
});

module.exports = router;
