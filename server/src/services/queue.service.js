const db = require('../db/pg_connection');

async function recalculateQueue(hospitalId) {
  const result = await db.query(
    `SELECT id, priority_level, validated_priority, created_at
     FROM tickets
     WHERE hospital_id = $1 AND status IN ('waiting', 'checked_in', 'triage')
     ORDER BY COALESCE(validated_priority, priority_level) ASC, created_at ASC`,
    [hospitalId],
  );

  for (let i = 0; i < result.rows.length; i++) {
    const ticket = result.rows[i];
    const priority = ticket.validated_priority || ticket.priority_level;
    const baseWait = { 1: 0, 2: 15, 3: 30, 4: 60, 5: 120 }[priority] || 60;

    await db.update('tickets', ticket.id, {
      queue_position: i + 1,
      estimated_wait_minutes: baseWait + i * 10,
    });
  }
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
  };
}

module.exports = { recalculateQueue, getQueueSummary };
