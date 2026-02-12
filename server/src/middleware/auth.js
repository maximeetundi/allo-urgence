const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../db/connection');

const JWT_SECRET = process.env.JWT_SECRET || 'allo-urgence-dev-secret';

function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Token d\'authentification requis' });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(403).json({ error: 'Token invalide ou expiré' });
    }
}

function requireRole(...roles) {
    return (req, res, next) => {
        if (!req.user) return res.status(401).json({ error: 'Non authentifié' });
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ error: 'Accès non autorisé pour ce rôle' });
        }
        next();
    };
}

function auditLog(action, userId, details) {
    try {
        db.insert('audit_log', {
            id: uuidv4(),
            user_id: userId || 'anonymous',
            action,
            details: typeof details === 'string' ? details : JSON.stringify(details),
            created_at: new Date().toISOString()
        });
    } catch (err) {
        console.error('Audit log error:', err.message);
    }
}

module.exports = { authenticateToken, requireRole, auditLog };
