const db = require('../db/pg_connection');

function initializeSocket(io) {
    io.on('connection', (socket) => {
        console.log('🔌 Client connecté:', socket.id);

        socket.on('join_hospital', (hospitalId) => {
            socket.join(`hospital_${hospitalId}`);
        });

        socket.on('leave_hospital', (hospitalId) => {
            socket.leave(`hospital_${hospitalId}`);
        });

        socket.on('join_ticket', (ticketId) => {
            socket.join(`ticket_${ticketId}`);
        });

        socket.on('disconnect', () => {
            console.log('❌ Client déconnecté:', socket.id);
        });
    });
}

module.exports = { initializeSocket };
