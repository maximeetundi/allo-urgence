const jwt = require('jsonwebtoken');
const db = require('../db/pg_connection');

const JWT_SECRET = process.env.JWT_SECRET || 'allo-urgence-dev-secret';

function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: "Token d'authentification requis" });
    }

    try {
        req.user = jwt.verify(token, JWT_SECRET);
        next();
    } catch {
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
    db.insert('audit_log', {
        user_id: userId || 'anonymous',
        action,
        details: typeof details === 'string' ? details : JSON.stringify(details),
    }).catch((err) => console.error('Audit log error:', err.message));
}

module.exports = { authenticateToken, requireRole, auditLog, JWT_SECRET };
