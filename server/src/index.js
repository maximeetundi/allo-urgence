require('dotenv').config();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs');

// Ensure data directory exists
const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
}

// Initialize database
const initDatabase = require('./db/init');
initDatabase();

const app = express();
const server = http.createServer(app);

// CORS configuration
const corsOptions = {
    origin: process.env.NODE_ENV === 'production' 
        ? ['https://api.allo-urgence.tech-afm.com', 'https://admin.allo-urgence.tech-afm.com', 'https://allo-urgence.tech-afm.com']
        : '*',
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    credentials: true
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
        const duration = Date.now() - start;
        if (duration > 300) {
            console.warn(`⚠️ Réponse lente: ${req.method} ${req.path} — ${duration}ms`);
        }
    });
    next();
});

// Routes
app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/tickets', require('./routes/ticket.routes'));
app.use('/api/hospitals', require('./routes/hospital.routes'));
app.use('/api/admin', require('./routes/admin.routes'));

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', service: 'Allo Urgence API', version: '1.0.0', timestamp: new Date().toISOString() });
});

// Socket.IO
const { initializeSocket } = require('./socket/index');
initializeSocket(io);

// Error handler
app.use((err, req, res, next) => {
    console.error('❌ Erreur:', err.message);
    res.status(500).json({ error: 'Erreur interne du serveur' });
});

const PORT = process.env.PORT || 3355;
const API_URL = process.env.API_URL || `http://localhost:${PORT}`;
server.listen(PORT, () => {
    console.log('');
    console.log('🏥 ═══════════════════════════════════════');
    console.log('🏥  Allo Urgence API Server');
    console.log(`🏥  Port: ${PORT}`);
    console.log(`🏥  URL:  ${API_URL}`);
    console.log(`🏥  Env:  ${process.env.NODE_ENV || 'development'}`);
    console.log('🏥 ═══════════════════════════════════════');
    console.log('');
    console.log('📡 WebSocket activé');
    console.log(`🌐 Health: ${API_URL}/api/health`);
    console.log('');
});

module.exports = { app, server, io };
