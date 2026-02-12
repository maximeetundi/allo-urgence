const db = require('../db/connection');
const { getEstimatedWait } = require('./triage.service');

function getQueueCounts(hospitalId) {
  const tickets = db.findMany('tickets', t =>
    t.hospital_id === hospitalId && ['waiting', 'checked_in', 'triage'].includes(t.status)
  );
  const counts = {};
  tickets.forEach(t => {
    const p = t.validated_priority || t.priority_level;
    counts[p] = (counts[p] || 0) + 1;
  });
  return counts;
}

function recalculateAllPositions(hospitalId) {
  const queueCounts = getQueueCounts(hospitalId);
  const tickets = db.findMany('tickets', t =>
    t.hospital_id === hospitalId && ['waiting', 'checked_in', 'triage'].includes(t.status)
  ).sort((a, b) => {
    const pa = a.validated_priority || a.priority_level;
    const pb = b.validated_priority || b.priority_level;
    if (pa !== pb) return pa - pb;
    return new Date(a.created_at) - new Date(b.created_at);
  });

  tickets.forEach((ticket, index) => {
    const effectivePriority = ticket.validated_priority || ticket.priority_level;
    db.update('tickets', ticket.id, {
      queue_position: index + 1,
      estimated_wait_minutes: getEstimatedWait(effectivePriority, queueCounts)
    });
  });

  return tickets.length;
}

function getQueueSummary(hospitalId) {
  const counts = getQueueCounts(hospitalId);
  const total = db.count('tickets', t =>
    t.hospital_id === hospitalId && ['waiting', 'checked_in', 'triage', 'in_progress'].includes(t.status)
  );

  const waitingTickets = db.findMany('tickets', t =>
    t.hospital_id === hospitalId && ['waiting', 'checked_in'].includes(t.status)
  );
  const avgWait = waitingTickets.length > 0
    ? Math.round(waitingTickets.reduce((sum, t) => sum + (t.estimated_wait_minutes || 0), 0) / waitingTickets.length)
    : 0;

  return { hospitalId, totalActive: total, byPriority: counts, averageWaitMinutes: avgWait };
}

module.exports = { getQueueCounts, recalculateAllPositions, getQueueSummary };
