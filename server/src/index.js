require('dotenv').config();

// Validate environment variables FIRST (fail-fast if misconfigured)
const { validateEnvVars, config } = require('./config/env');
validateEnvVars();

const path = require('path');
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./utils/logger');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const { apiLimiter } = require('./middleware/rateLimiter');
const initDatabase = require('./db/pg_init'); // Import DB init

// Initialize Database (Async)
initDatabase().catch(err => {
    logger.error('Database initialization failed:', err);
    process.exit(1);
});

const app = express();
app.set('trust proxy', 1); // Trust first proxy (Docker/Nginx)
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

// Serve uploads statically
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

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
app.use('/api/upload', require('./routes/upload.routes'));

// Health
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', service: 'Allo Urgence API', version: '1.0.0', timestamp: new Date().toISOString() });
});

// Initialize WebSocket
const { initializeWebSocket } = require('./services/websocket.service');
// io is already initialized and exported by websocket.service if needed, 
// but here we initialize it with the server instance
// io is already initialized and exported by websocket.service if needed, 
// but here we initialize it with the server instance
// io is already declared above through require on line 87 (if it was destructured), 
// but actually the require line 87 is destructuring initializeWebSocket, not io.
// The error says io is already declared. Let me check line 87 again.
// Line 87: const { initializeWebSocket } = require('./services/websocket.service');
// Line 88: const io = initializeWebSocket(server);
// Line 100: module.exports = { app, server, io };
//
// Wait, looking at the previous file content view:
// 86: // Initialize WebSocket
// 87: const { initializeWebSocket } = require('./services/websocket.service');
// 88: const io = initializeWebSocket(server);
//
// The error 'Identifier io has already been declared' implies io is declared somewhere else in this file.
// I need to look at the whole file to be sure.
// However, I suspect I might have imported 'io' in a previous edit or it's being declared twice.
// Let me look at the top of the file.

// Make io available to routes
app.set('io', io);

// Error handlers (must be last)
app.use(notFoundHandler);
app.use(errorHandler);



const PORT = process.env.PORT || 3355;
server.listen(PORT, '0.0.0.0', () => {
    logger.info(`Serveur démarré sur le port ${PORT}`);
    logger.info(`Documentation API disponible sur ${process.env.FRONTEND_URL || 'http://localhost:3000'}`);
});

module.exports = { app, server, io };
