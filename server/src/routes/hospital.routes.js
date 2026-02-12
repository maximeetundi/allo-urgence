const express = require('express');
const db = require('../db/connection');
const { authenticateToken } = require('../middleware/auth');
const { getQueueSummary } = require('../services/queue.service');

const router = express.Router();

// GET /api/hospitals
router.get('/', (req, res) => {
  const hospitals = db.findMany('hospitals').sort((a, b) => a.name.localeCompare(b.name));
  res.json({ hospitals });
});

// GET /api/hospitals/:id
router.get('/:id', (req, res) => {
  const hospital = db.findById('hospitals', req.params.id);
  if (!hospital) return res.status(404).json({ error: 'Hôpital non trouvé' });
  res.json(hospital);
});

// GET /api/hospitals/:id/stats
router.get('/:id/stats', (req, res) => {
  const hospital = db.findById('hospitals', req.params.id);
  if (!hospital) return res.status(404).json({ error: 'Hôpital non trouvé' });

  const summary = getQueueSummary(req.params.id);

  const today = new Date().toISOString().split('T')[0];
  const treatedToday = db.count('tickets', t =>
    t.hospital_id === req.params.id && t.status === 'treated' && t.updated_at?.startsWith(today)
  );

  res.json({
    hospital, queue: summary,
    todayStats: { treatedToday }
  });
});

module.exports = router;
