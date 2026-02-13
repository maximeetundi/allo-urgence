const express = require('express');
const router = express.Router();
const db = require('../db/pg_connection');
const { authenticateToken } = require('../middleware/auth');

// ── GET /api/hospitals — list all hospitals ─────────────────────
router.get('/', async (req, res) => {
  try {
    const hospitals = await db.findMany('hospitals', null, 'nom ASC');
    res.json({ hospitals });
  } catch (err) {
    console.error('Hospitals list error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// ── GET /api/hospitals/:id — hospital detail + stats ────────────
router.get('/:id', async (req, res) => {
  try {
    const hospital = await db.findById('hospitals', req.params.id);
    if (!hospital) return res.status(404).json({ error: 'Hôpital non trouvé' });

    const activeTickets = await db.count('tickets', { hospital_id: hospital.id, status: 'waiting' });
    const checkedIn = await db.count('tickets', { hospital_id: hospital.id, status: 'checked_in' });

    res.json({ ...hospital, stats: { activeTickets, checkedIn } });
  } catch (err) {
    console.error('Hospital detail error:', err.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

module.exports = router;
