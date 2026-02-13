require('dotenv').config();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');

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

// Performance monitoring
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const ms = Date.now() - start;
        if (ms > 500) console.warn(`⚠️ Slow: ${req.method} ${req.path} — ${ms}ms`);
    });
    next();
});

// Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/tickets', require('./routes/ticket.routes'));
app.use('/api/hospitals', require('./routes/hospital.routes'));
app.use('/api/admin', require('./routes/admin.routes'));

// Health
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', service: 'Allo Urgence API', version: '1.0.0', timestamp: new Date().toISOString() });
});

// Socket.IO
const { initializeSocket } = require('./socket/index');
initializeSocket(io);

// Error handler
app.use((err, req, res, _next) => {
    console.error('❌ Erreur:', err.message);
    res.status(500).json({ error: 'Erreur interne du serveur' });
});

// ── Start ───────────────────────────────────────────────────────
const PORT = process.env.PORT || 3355;

async function start() {
    // Initialize database (create tables + seed)
    const initDatabase = require('./db/pg_init');
    await initDatabase();

    server.listen(PORT, () => {
        console.log('');
        console.log('🏥 ═══════════════════════════════════════');
        console.log('🏥  Allo Urgence API Server');
        console.log(`🏥  Port: ${PORT}`);
        console.log(`🏥  Env:  ${process.env.NODE_ENV || 'development'}`);
        console.log('🏥 ═══════════════════════════════════════');
        console.log('');
    });
}

start().catch((err) => {
    console.error('❌ Failed to start:', err.message);
    process.exit(1);
});

module.exports = { app, server, io };
