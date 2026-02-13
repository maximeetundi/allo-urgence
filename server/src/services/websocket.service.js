const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');
const { getQueueSummary } = require('./queue.service');
const db = require('../db/pg_connection');

let io = null;

/**
 * Initialize Socket.IO server
 * @param {Object} httpServer - HTTP server instance
 */
function initializeWebSocket(httpServer) {
    io = new Server(httpServer, {
        cors: {
            origin: process.env.CORS_ORIGIN || '*',
            methods: ['GET', 'POST'],
            credentials: true,
        },
        pingTimeout: 60000,
        pingInterval: 25000,
    });

    // Authentication middleware
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');

            if (!token) {
                return next(new Error('Authentication required'));
            }

            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            socket.userId = decoded.id;
            socket.userRole = decoded.role;

            logger.info('WebSocket authenticated', { userId: decoded.id, role: decoded.role });
            next();
        } catch (err) {
            logger.error('WebSocket auth error', { error: err.message });
            next(new Error('Invalid token'));
        }
    });

    // Connection handler
    io.on('connection', (socket) => {
        logger.info('WebSocket connected', {
            socketId: socket.id,
            userId: socket.userId,
            role: socket.userRole,
        });

        // Join user's personal room
        socket.join(`user_${socket.userId}`);

        // Handle hospital room join (for staff)
        socket.on('join_hospital', async (hospitalId) => {
            if (['nurse', 'doctor', 'admin'].includes(socket.userRole)) {
                socket.join(`hospital_${hospitalId}`);
                logger.info('Joined hospital room', { userId: socket.userId, hospitalId });

                // Send initial queue summary
                try {
                    const summary = await getQueueSummary(hospitalId);
                    socket.emit('queue_summary', summary);
                } catch (err) {
                    logger.error('Error sending queue summary', { error: err.message });
                }
            }
        });

        // Handle ticket room join (for patients)
        socket.on('join_ticket', async (ticketId) => {
            try {
                const ticket = await db.findById('tickets', ticketId);

                // Verify ownership or staff access
                if (ticket.patient_id === socket.userId || ['nurse', 'doctor', 'admin'].includes(socket.userRole)) {
                    socket.join(`ticket_${ticketId}`);
                    logger.info('Joined ticket room', { userId: socket.userId, ticketId });

                    // Send current ticket status
                    socket.emit('ticket_status', ticket);
                } else {
                    socket.emit('error', { message: 'Access denied to this ticket' });
                }
            } catch (err) {
                logger.error('Error joining ticket room', { error: err.message });
                socket.emit('error', { message: 'Failed to join ticket room' });
            }
        });

        // Handle leave hospital
        socket.on('leave_hospital', (hospitalId) => {
            socket.leave(`hospital_${hospitalId}`);
            logger.info('Left hospital room', { userId: socket.userId, hospitalId });
        });

        // Handle leave ticket
        socket.on('leave_ticket', (ticketId) => {
            socket.leave(`ticket_${ticketId}`);
            logger.info('Left ticket room', { userId: socket.userId, ticketId });
        });

        // Disconnect handler
        socket.on('disconnect', (reason) => {
            logger.info('WebSocket disconnected', {
                socketId: socket.id,
                userId: socket.userId,
                reason,
            });
        });

        // Error handler
        socket.on('error', (err) => {
            logger.error('WebSocket error', {
                socketId: socket.id,
                userId: socket.userId,
                error: err.message,
            });
        });
    });

    logger.info('WebSocket server initialized');
    return io;
}

/**
 * Get Socket.IO instance
 */
function getIO() {
    if (!io) {
        throw new Error('Socket.IO not initialized');
    }
    return io;
}

/**
 * Emit queue update to hospital room
 */
async function emitQueueUpdate(hospitalId) {
    if (!io) return;

    try {
        const summary = await getQueueSummary(hospitalId);
        io.to(`hospital_${hospitalId}`).emit('queue_update', summary);
        logger.info('Queue update emitted', { hospitalId });
    } catch (err) {
        logger.error('Error emitting queue update', { error: err.message });
    }
}

/**
 * Emit ticket update to patient and hospital
 */
function emitTicketUpdate(ticket) {
    if (!io) return;

    try {
        // To patient
        io.to(`user_${ticket.patient_id}`).emit('ticket_update', ticket);
        io.to(`ticket_${ticket.id}`).emit('ticket_update', ticket);

        // To hospital staff
        io.to(`hospital_${ticket.hospital_id}`).emit('ticket_changed', ticket);

        logger.info('Ticket update emitted', { ticketId: ticket.id });
    } catch (err) {
        logger.error('Error emitting ticket update', { error: err.message });
    }
}

/**
 * Emit critical alert to hospital
 */
function emitCriticalAlert(hospitalId, ticket) {
    if (!io) return;

    try {
        io.to(`hospital_${hospitalId}`).emit('critical_alert', {
            ticketId: ticket.id,
            priority: ticket.priority_level,
            patientName: `${ticket.patient_prenom} ${ticket.patient_nom}`,
            timestamp: new Date().toISOString(),
        });

        logger.warn('Critical alert emitted', { hospitalId, ticketId: ticket.id });
    } catch (err) {
        logger.error('Error emitting critical alert', { error: err.message });
    }
}

/**
 * Emit notification to specific user
 */
function emitNotification(userId, notification) {
    if (!io) return;

    try {
        io.to(`user_${userId}`).emit('notification', notification);
        logger.info('Notification emitted', { userId, type: notification.type });
    } catch (err) {
        logger.error('Error emitting notification', { error: err.message });
    }
}

module.exports = {
    initializeWebSocket,
    getIO,
    emitQueueUpdate,
    emitTicketUpdate,
    emitCriticalAlert,
    emitNotification,
};
