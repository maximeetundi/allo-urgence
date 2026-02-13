require('dotenv').config();

// Validate environment variables FIRST (fail-fast if misconfigured)
const { validateEnvVars, config } = require('./config/env');
validateEnvVars();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./utils/logger');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const { apiLimiter } = require('./middleware/rateLimiter');

const app = express();
const server = http.createServer(app);

const corsOptions = {
    origin: (origin, callback) => {
        const allowedOrigins = [
            'https://api.allo-urgence.tech-afm.com',
            'https://admin.allo-urgence.tech-afm.com',
            'https://allo-urgence.tech-afm.com'
        ];
        // Allow requests with no origin (like mobile apps/Postman) or localhost for dev/testing
        if (!origin || origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
            return callback(null, true);
        }
        if (allowedOrigins.indexOf(origin) !== -1) {
            return callback(null, true);
        } else {
            return callback(new Error('Not allowed by CORS'));
        }
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
};

const io = new Server(server, { cors: corsOptions });
app.set('io', io);

// Middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));

// Rate limiting
app.use('/api/', apiLimiter);

// Performance monitoring
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const ms = Date.now() - start;
        if (ms > 500) {
            logger.warn('Slow request', {
                method: req.method,
                path: req.path,
                duration: `${ms}ms`,
                ip: req.ip,
            });
        }
    });
    next();
});

// Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/tickets', require('./routes/ticket.routes'));
app.use('/api/hospitals', require('./routes/hospital.routes'));
app.use('/api/admin', require('./routes/admin.routes'));
app.use('/api/triage', require('./routes/triage.routes'));
app.use('/api/nurse', require('./routes/nurse.routes'));
app.use('/api/doctor', require('./routes/doctor.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));
app.use('/api/qr', require('./routes/qr.routes'));
app.use('/api/share', require('./routes/share.routes'));

// Health
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', service: 'Allo Urgence API', version: '1.0.0', timestamp: new Date().toISOString() });
});

// Initialize WebSocket
const { initializeWebSocket } = require('./services/websocket.service');
const io = initializeWebSocket(server);

// Make io available to routes
app.set('io', io);

// Error handlers (must be last)
app.use(notFoundHandler);
app.use(errorHandler);

process.exit(1);
});

module.exports = { app, server, io };
