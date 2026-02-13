const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const db = require('../db/pg_connection');
const { authenticateToken, requireRole, auditLog } = require('../middleware/auth');

// ── GET /api/admin/stats ────────────────────────────────────────
router.get('/stats', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const totalUsers = await db.count('users');
    const totalHospitals = await db.count('hospitals');
    const totalTickets = await db.count('tickets');
    const activeTickets = await db.query(
      `SELECT COUNT(*)::int AS count FROM tickets WHERE status IN ('waiting','checked_in','triage','in_progress')`,
    );
    const avgWait = await db.query(
      `SELECT COALESCE(AVG(estimated_wait_minutes), 0)::int AS avg FROM tickets WHERE status IN ('waiting','checked_in')`,
    );
    const byStatus = await db.query(
      `SELECT status, COUNT(*)::int AS count FROM tickets GROUP BY status`,
    );
    const byPriority = await db.query(
      `SELECT COALESCE(validated_priority, priority_level) AS priority, COUNT(*)::int AS count
       FROM tickets WHERE status IN ('waiting','checked_in','triage','in_progress')
       GROUP BY priority ORDER BY priority`,
    );

    res.json({
      totalUsers,
      totalHospitals,
      totalTickets,
      activeTickets: activeTickets.rows[0]?.count || 0,
      avgWaitTime: avgWait.rows[0]?.avg || 0,
      byStatus: byStatus.rows,
      byPriority: byPriority.rows,
    });
  } catch (err) {
    console.error('Admin stats error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── GET /api/admin/users ────────────────────────────────────────
router.get('/users', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, role, email, nom, prenom, telephone, created_at FROM users ORDER BY created_at DESC`,
    );
    res.json({ users: result.rows });
  } catch (err) {
    console.error('Admin users error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── POST /api/admin/users ───────────────────────────────────────
router.post('/users', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { email, password, nom, prenom, role, telephone } = req.body;
    if (!email || !password || !nom || !prenom || !role) {
      return res.status(400).json({ error: 'Champs obligatoires manquants' });
    }

    const existing = await db.findOne('users', { email });
    if (existing) return res.status(409).json({ error: 'Courriel déjà utilisé' });

    const password_hash = bcrypt.hashSync(password, 10);
    const user = await db.insert('users', {
      role, email, password_hash, nom, prenom, telephone: telephone || null,
    });

    auditLog('user_created', req.user.id, { newUserId: user.id, role });
    const { password_hash: _, ...safeUser } = user;
    res.status(201).json(safeUser);
  } catch (err) {
    console.error('Admin create user error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── DELETE /api/admin/users/:id ─────────────────────────────────
router.delete('/users/:id', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    if (req.params.id === req.user.id) {
      return res.status(400).json({ error: 'Impossible de supprimer votre propre compte' });
    }
    const deleted = await db.delete('users', req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Utilisateur non trouvé' });
    auditLog('user_deleted', req.user.id, { deletedUserId: req.params.id });
    res.json({ message: 'Utilisateur supprimé' });
  } catch (err) {
    console.error('Admin delete user error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── GET /api/admin/hospitals ────────────────────────────────────
router.get('/hospitals', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const hospitals = await db.findMany('hospitals', null, 'name ASC');
    res.json({ hospitals });
  } catch (err) {
    console.error('Admin hospitals error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── POST /api/admin/hospitals ───────────────────────────────────
router.post('/hospitals', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { name, address, latitude, longitude, capacity } = req.body;
    if (!name || !address) return res.status(400).json({ error: 'Nom et adresse requis' });

    const hospital = await db.insert('hospitals', {
      name, address,
      latitude: latitude || null,
      longitude: longitude || null,
      capacity: capacity || 100,
    });

    auditLog('hospital_created', req.user.id, { hospitalId: hospital.id });
    res.status(201).json(hospital);
  } catch (err) {
    console.error('Admin create hospital error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── PATCH /api/admin/hospitals/:id ──────────────────────────────
router.patch('/hospitals/:id', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { name, address, latitude, longitude, capacity } = req.body;
    const updates = {};
    if (name !== undefined) updates.name = name;
    if (address !== undefined) updates.address = address;
    if (latitude !== undefined) updates.latitude = latitude;
    if (longitude !== undefined) updates.longitude = longitude;
    if (capacity !== undefined) updates.capacity = capacity;

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'Aucune modification' });
    }

    const updated = await db.update('hospitals', req.params.id, updates);
    if (!updated) return res.status(404).json({ error: 'Hôpital non trouvé' });
    res.json(updated);
  } catch (err) {
    console.error('Admin update hospital error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── DELETE /api/admin/hospitals/:id ─────────────────────────────
router.delete('/hospitals/:id', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const deleted = await db.delete('hospitals', req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Hôpital non trouvé' });
    auditLog('hospital_deleted', req.user.id, { hospitalId: req.params.id });
    res.json({ message: 'Hôpital supprimé' });
  } catch (err) {
    console.error('Admin delete hospital error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── GET /api/admin/tickets ──────────────────────────────────────
router.get('/tickets', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { status, priority, hospital_id } = req.query;
    let query = 'SELECT * FROM tickets';
    const conditions = [];
    const values = [];
    let i = 1;

    if (status) { conditions.push(`status = $${i++}`); values.push(status); }
    if (priority) { conditions.push(`COALESCE(validated_priority, priority_level) = $${i++}`); values.push(parseInt(priority)); }
    if (hospital_id) { conditions.push(`hospital_id = $${i++}`); values.push(hospital_id); }

    if (conditions.length > 0) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY created_at DESC LIMIT 100';

    const result = await db.query(query, values);
    res.json({ tickets: result.rows });
  } catch (err) {
    console.error('Admin tickets error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── PATCH /api/admin/tickets/:id ────────────────────────────────
router.patch('/tickets/:id', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const { status, priority, hospital_id } = req.body;
    const updates = {};

    if (status) updates.status = status;
    if (priority) {
      updates.validated_priority = parseInt(priority);
      // Also update base priority if not validated yet? No, keep original as trace.
    }
    if (hospital_id) updates.hospital_id = hospital_id;

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'Aucune modification fournie' });
    }

    const ticket = await db.findById('tickets', req.params.id);
    if (!ticket) return res.status(404).json({ error: 'Ticket non trouvé' });

    const updated = await db.update('tickets', req.params.id, updates);

    // Notify via socket
    const io = req.app.get('io');
    if (io) {
      io.to(`ticket_${ticket.id}`).emit('ticket_update', updated);
      io.to(`hospital_${updated.hospital_id}`).emit('queue_update', await require('../services/queue.service').getQueueSummary(updated.hospital_id));
    }

    auditLog('ticket_admin_update', req.user.id, { ticketId: ticket.id, updates });
    res.json(updated);
  } catch (err) {
    console.error('Admin update ticket error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
