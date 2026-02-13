const db = require('../db/pg_connection');
const logger = require('../utils/logger');

async function recalculateQueue(hospitalId) {
  const result = await db.query(
    `SELECT id, patient_id, priority_level, validated_priority, created_at
     FROM tickets
     WHERE hospital_id = $1 AND status IN ('waiting', 'checked_in', 'triage')
     ORDER BY COALESCE(validated_priority, priority_level) ASC, created_at ASC`,
    [hospitalId],
  );

  const updatedTickets = [];

  for (let i = 0; i < result.rows.length; i++) {
    const ticket = result.rows[i];
    const priority = ticket.validated_priority || ticket.priority_level;
    const baseWait = { 1: 0, 2: 15, 3: 30, 4: 60, 5: 120 }[priority] || 60;
    const newPosition = i + 1;
    const newWaitTime = baseWait + i * 10;

    const updated = await db.update('tickets', ticket.id, {
      queue_position: newPosition,
      estimated_wait_minutes: newWaitTime,
    });

    updatedTickets.push(updated);

    // Emit individual ticket update via WebSocket
    try {
      const { emitTicketUpdate } = require('./websocket.service');
      emitTicketUpdate(updated);
    } catch (err) {
      logger.error('Error emitting ticket update', { error: err.message });
    }
  }

  // Emit queue summary update
  try {
    const { emitQueueUpdate } = require('./websocket.service');
    await emitQueueUpdate(hospitalId);
  } catch (err) {
    logger.error('Error emitting queue update', { error: err.message });
  }

  return updatedTickets;
}

async function getQueueSummary(hospitalId) {
  const result = await db.query(
    `SELECT status, COALESCE(validated_priority, priority_level) AS prio, COUNT(*)::int AS cnt
     FROM tickets
     WHERE hospital_id = $1 AND status IN ('waiting','checked_in','triage','in_progress')
     GROUP BY status, prio
     ORDER BY prio`,
    [hospitalId],
  );

  const byPriority = {};
  let totalActive = 0;
  result.rows.forEach((r) => {
    byPriority[r.prio] = (byPriority[r.prio] || 0) + r.cnt;
    totalActive += r.cnt;
  });

  const avgResult = await db.query(
    `SELECT COALESCE(AVG(estimated_wait_minutes), 0)::int AS avg
     FROM tickets
     WHERE hospital_id = $1 AND status IN ('waiting','checked_in')`,
    [hospitalId],
  );

  return {
    totalActive,
    byPriority,
    averageWaitMinutes: avgResult.rows[0]?.avg || 0,
    timestamp: new Date().toISOString(),
  };
}

module.exports = { recalculateQueue, getQueueSummary };
