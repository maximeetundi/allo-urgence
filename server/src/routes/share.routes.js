const express = require('express');
const router = express.Router();
const db = require('../db/pg_connection');
const { authenticateToken } = require('../middleware/auth');
const crypto = require('crypto');

// ── POST /api/share/create ────────────────────────────────────
// Create shareable link for ticket
router.post('/create', authenticateToken, async (req, res) => {
    try {
        const { ticket_id } = req.body;

        if (!ticket_id) {
            return res.status(400).json({ error: 'ticket_id required' });
        }

        // Verify ticket belongs to user
        const ticketResult = await db.query(
            'SELECT * FROM tickets WHERE id = $1 AND patient_id = $2',
            [ticket_id, req.user.id]
        );

        if (ticketResult.rows.length === 0) {
            return res.status(404).json({ error: 'Ticket not found' });
        }

        // Generate unique share token
        const shareToken = crypto.randomBytes(32).toString('hex');
        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

        // Store share token
        await db.query(
            `INSERT INTO share_tokens (ticket_id, token, expires_at, created_by)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (ticket_id) 
       DO UPDATE SET token = $2, expires_at = $3, revoked = false, updated_at = CURRENT_TIMESTAMP`,
            [ticket_id, shareToken, expiresAt, req.user.id]
        );

        // Generate shareable URL
        const shareUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/share/${shareToken}`;

        res.json({
            share_url: shareUrl,
            token: shareToken,
            expires_at: expiresAt,
        });
    } catch (error) {
        console.error('Error creating share link:', error);
        res.status(500).json({ error: 'Error creating share link' });
    }
});

// ── GET /api/share/:token ──────────────────────────────────────
// Get ticket status via share token (public, no auth)
router.get('/:token', async (req, res) => {
    try {
        const { token } = req.params;

        // Get share token
        const shareResult = await db.query(
            `SELECT * FROM share_tokens 
       WHERE token = $1 AND revoked = false AND expires_at > CURRENT_TIMESTAMP`,
            [token]
        );

        if (shareResult.rows.length === 0) {
            return res.status(404).json({ error: 'Share link expired or invalid' });
        }

        const share = shareResult.rows[0];

        // Get ticket info
        const ticketResult = await db.query(
            `SELECT 
        t.id, t.priority_level, t.status, t.queue_position, 
        t.estimated_wait_minutes, t.created_at,
        h.name as hospital_name, h.address as hospital_address
       FROM tickets t
       JOIN hospitals h ON t.hospital_id = h.id
       WHERE t.id = $1`,
            [share.ticket_id]
        );

        if (ticketResult.rows.length === 0) {
            return res.status(404).json({ error: 'Ticket not found' });
        }

        const ticket = ticketResult.rows[0];

        res.json({
            ticket: {
                id: ticket.id,
                priority_level: ticket.priority_level,
                status: ticket.status,
                queue_position: ticket.queue_position,
                estimated_wait_minutes: ticket.estimated_wait_minutes,
                created_at: ticket.created_at,
                hospital_name: ticket.hospital_name,
                hospital_address: ticket.hospital_address,
            },
            expires_at: share.expires_at,
        });
    } catch (error) {
        console.error('Error getting shared ticket:', error);
        res.status(500).json({ error: 'Error retrieving ticket' });
    }
});

// ── DELETE /api/share/revoke ───────────────────────────────────
// Revoke share link
router.delete('/revoke', authenticateToken, async (req, res) => {
    try {
        const { ticket_id } = req.body;

        await db.query(
            `UPDATE share_tokens 
       SET revoked = true, updated_at = CURRENT_TIMESTAMP
       WHERE ticket_id = $1 AND created_by = $2`,
            [ticket_id, req.user.id]
        );

        res.json({ message: 'Share link revoked' });
    } catch (error) {
        console.error('Error revoking share link:', error);
        res.status(500).json({ error: 'Error revoking share link' });
    }
});

module.exports = router;
