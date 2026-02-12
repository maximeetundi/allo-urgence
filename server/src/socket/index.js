const { getQueueSummary } = require('../services/queue.service');

function initializeSocket(io) {
    io.on('connection', (socket) => {
        console.log(`🔌 Client connecté: ${socket.id}`);

        // Join hospital room for real-time updates
        socket.on('join_hospital', (hospitalId) => {
            socket.join(`hospital:${hospitalId}`);
            console.log(`📡 ${socket.id} rejoint l'hôpital ${hospitalId}`);

            // Send current queue state
            try {
                const summary = getQueueSummary(hospitalId);
                socket.emit('queue_update', summary);
            } catch (err) {
                console.error('Error getting queue summary:', err);
            }
        });

        // Join ticket room for patient-specific updates
        socket.on('join_ticket', (ticketId) => {
            socket.join(`ticket:${ticketId}`);
            console.log(`🎫 ${socket.id} suit le ticket ${ticketId}`);
        });

        // Leave rooms
        socket.on('leave_hospital', (hospitalId) => {
            socket.leave(`hospital:${hospitalId}`);
        });

        socket.on('leave_ticket', (ticketId) => {
            socket.leave(`ticket:${ticketId}`);
        });

        socket.on('disconnect', () => {
            console.log(`❌ Client déconnecté: ${socket.id}`);
        });
    });
}

module.exports = { initializeSocket };
